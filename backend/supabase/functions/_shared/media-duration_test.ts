import { detectMediaDuration } from './media-duration.ts';

const assertNear = (actual: number | null, expected: number) => {
  if (actual == null || Math.abs(actual - expected) > 0.01) {
    throw new Error(`Expected ${expected}s, received ${actual}s`);
  }
};

Deno.test('reads duration from an MP4 mvhd atom', () => {
  const bytes = new Uint8Array(40);
  bytes.set([0x6d, 0x76, 0x68, 0x64], 4); // mvhd
  const view = new DataView(bytes.buffer);
  view.setUint32(20, 1000, false);
  view.setUint32(24, 30_500, false);
  assertNear(detectMediaDuration(bytes, 'video/mp4'), 30.5);
});

Deno.test('reads duration from a WebM Duration element', () => {
  const bytes = new Uint8Array(20);
  bytes.set([0x1a, 0x45, 0xdf, 0xa3], 0);
  bytes.set([0x44, 0x89, 0x88], 5); // Duration + 8-byte size
  new DataView(bytes.buffer).setFloat64(8, 31_250, false);
  assertNear(detectMediaDuration(bytes, 'video/webm'), 31.25);
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
