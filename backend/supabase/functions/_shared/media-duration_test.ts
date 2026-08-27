import { detectMediaDuration } from './media-duration.ts';

const assertNear = (actual: number | null, expected: number) => {
  if (actual == null || Math.abs(actual - expected) > 0.01) {
    throw new Error(`Expected ${expected}s, received ${actual}s`);
  }
};

const concat = (...parts: (number[] | Uint8Array)[]): Uint8Array =>
  Uint8Array.from(parts.flatMap((p) => Array.from(p)));

/** Encodes an EBML size vint of the given byte length (marker bit included). */
const size = (length: number, value: number): number[] => {
  const bytes = new Array(length).fill(0);
  let v = value;
  for (let i = length - 1; i >= 1; i--) {
    bytes[i] = v & 0xff;
    v = Math.floor(v / 256);
  }
  const marker = 1 << (8 - length);
  bytes[0] = marker | (v & (marker - 1));
  return bytes;
};

const float64Bytes = (value: number): number[] => {
  const buf = new ArrayBuffer(8);
  new DataView(buf).setFloat64(0, value, false);
  return Array.from(new Uint8Array(buf));
};

Deno.test('reads duration from an MP4 mvhd atom', () => {
  const bytes = new Uint8Array(40);
  bytes.set([0x6d, 0x76, 0x68, 0x64], 4); // mvhd
  const view = new DataView(bytes.buffer);
  view.setUint32(20, 1000, false);
  view.setUint32(24, 30_500, false);
  assertNear(detectMediaDuration(bytes, 'video/mp4'), 30.5);
});

Deno.test('reads duration from a WebM Duration element nested in Segment > Info', () => {
  // TimecodeScale = 500_000 ns/tick
  const timecodeScale = concat([0x2a, 0xd7, 0xb1], size(1, 4), [0x00, 0x07, 0xa1, 0x20]);
  // Duration = 62_500 ticks -> 62_500 * 500_000 / 1e9 = 31.25s
  const duration = concat([0x44, 0x89], size(1, 8), float64Bytes(62_500));
  const info = concat([0x15, 0x49, 0xa9, 0x66], size(1, timecodeScale.length + duration.length), timecodeScale, duration);
  const segment = concat([0x18, 0x53, 0x80, 0x67], size(1, info.length), info);
  // A sibling EBML header element should be skipped without confusing the parser.
  const ebmlHeader = concat([0x1a, 0x45, 0xdf, 0xa3], size(1, 4), [0x00, 0x00, 0x00, 0x00]);

  assertNear(detectMediaDuration(concat(ebmlHeader, segment), 'video/webm'), 31.25);
});

Deno.test('falls back to Cluster/SimpleBlock timecodes when Duration is absent, ignoring false-positive byte patterns inside frame data', () => {
  const timecode = concat([0xe7], size(1, 1), [0x00]);
  const trackVint = [0x81]; // track number 1
  const relativeTimecode = [0x75, 0x30]; // 30_000 (big-endian int16)
  const flags = [0x80];
  // Frame payload bytes deliberately contain byte sequences that used to be
  // misread as Cluster Timecode / SimpleBlock / Duration / TimecodeScale IDs
  // by the old flat byte-scanner.
  const noisyFrameData = [0xa3, 0xe7, 0x44, 0x89, 0x2a, 0xd7, 0xb1];
  const simpleBlockContent = [...trackVint, ...relativeTimecode, ...flags, ...noisyFrameData];
  const simpleBlock = concat([0xa3], size(1, simpleBlockContent.length), simpleBlockContent);
  const cluster = concat([0x1f, 0x43, 0xb6, 0x75], size(1, timecode.length + simpleBlock.length), timecode, simpleBlock);
  const segment = concat([0x18, 0x53, 0x80, 0x67], size(1, cluster.length), cluster);

  // Default TimecodeScale is 1_000_000 ns/tick -> 30_000 * 1_000_000 / 1e9 = 30s
  assertNear(detectMediaDuration(segment, 'video/webm'), 30);
});

Deno.test('reads duration across multiple unknown-size Clusters in a streamed/timesliced WebM', () => {
  // Mimics MediaRecorder.start(timeslice): the Segment and every Cluster are
  // written with EBML "unknown size" since the muxer doesn't know final
  // sizes while still recording. An unknown-size element is only implicitly
  // terminated by the next element that can't be its child (here: the next
  // Cluster ID, or end of buffer for the last one).
  const unknownSize1 = [0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]; // 8-byte unknown-size marker

  const buildCluster = (timecodeTicks: number, relativeTicks: number) => {
    const timecode = concat([0xe7], size(1, 2), [(timecodeTicks >> 8) & 0xff, timecodeTicks & 0xff]);
    const trackVint = [0x81];
    const relBytes = [(relativeTicks >> 8) & 0xff, relativeTicks & 0xff];
    const flags = [0x80];
    const simpleBlockContent = [...trackVint, ...relBytes, ...flags, 0xde, 0xad, 0xbe, 0xef];
    const simpleBlock = concat([0xa3], size(1, simpleBlockContent.length), simpleBlockContent);
    // Cluster itself has unknown size (only ends when the next Cluster ID appears).
    return concat([0x1f, 0x43, 0xb6, 0x75], unknownSize1, timecode, simpleBlock);
  };

  const cluster1 = buildCluster(0, 0); // timecode 0
  const cluster2 = buildCluster(10_000, 0); // timecode 10_000 ticks -> 10s
  const cluster3 = buildCluster(29_000, 500); // timecode 29_000 + 500 relative -> 29.5s

  const segmentContent = concat(cluster1, cluster2, cluster3);
  // Segment also has unknown size, as written by a live/streaming muxer.
  const segment = concat([0x18, 0x53, 0x80, 0x67], unknownSize1, segmentContent);

  // Default TimecodeScale is 1_000_000 ns/tick -> 29_500 * 1_000_000 / 1e9 = 29.5s
  assertNear(detectMediaDuration(segment, 'audio/webm;codecs=opus'), 29.5);
});

Deno.test('reads duration from a WAV data chunk', () => {
  const bytes = new Uint8Array(44);
  bytes.set(new TextEncoder().encode('RIFF'), 0);
  bytes.set(new TextEncoder().encode('WAVE'), 8);
  bytes.set(new TextEncoder().encode('data'), 36);
  const view = new DataView(bytes.buffer);
  view.setUint32(28, 16_000, true);
  view.setUint32(40, 480_000, true);
  assertNear(detectMediaDuration(bytes, 'audio/wav'), 30);
});
