const ascii = (bytes: Uint8Array, offset: number, length: number) =>
  String.fromCharCode(...bytes.subarray(offset, offset + length));

const uint32 = (view: DataView, offset: number) => view.getUint32(offset, false);

function mp4Duration(bytes: Uint8Array): number | null {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  for (let i = 4; i + 36 <= bytes.length; i++) {
    if (ascii(bytes, i, 4) !== 'mvhd') continue;
    const version = bytes[i + 4];
    if (version === 0 && i + 24 <= bytes.length) {
      const timescale = uint32(view, i + 16);
      const duration = uint32(view, i + 20);
      if (timescale > 0 && duration > 0) return duration / timescale;
    }
    if (version === 1 && i + 40 <= bytes.length) {
      const timescale = uint32(view, i + 28);
      const duration = Number(view.getBigUint64(i + 32, false));
      if (timescale > 0 && duration > 0) return duration / timescale;
    }
  }
  return null;
}

function readVint(bytes: Uint8Array, offset: number, keepMarker = false) {
  if (offset >= bytes.length) return null;
  const first = bytes[offset];
  let length = 1;
  let mask = 0x80;
  while (length <= 8 && (first & mask) === 0) {
    length++;
    mask >>= 1;
  }
  if (length > 8 || offset + length > bytes.length) return null;
  let value = keepMarker ? first : first & (mask - 1);
  for (let i = 1; i < length; i++) value = value * 256 + bytes[offset + i];
  return { length, value };
}

function readUnsigned(bytes: Uint8Array, offset: number, length: number) {
  if (length < 1 || length > 8 || offset + length > bytes.length) return null;
  let value = 0;
  for (let i = 0; i < length; i++) value = value * 256 + bytes[offset + i];
  return value;
}

// EBML element IDs (canonical byte-encoded form, marker bit included).
const SEGMENT_ID = 0x18538067;
const INFO_ID = 0x1549a966;
const CLUSTER_ID = 0x1f43b675;
const TIMECODE_SCALE_ID = 0x2ad7b1;
const DURATION_ID = 0x4489;
const TIMECODE_ID = 0xe7;
const SIMPLE_BLOCK_ID = 0xa3;

interface ElementHeader {
  id: number;
  contentStart: number;
  /** -1 means "unknown size" (extends to the end of the parent range). */
  contentLength: number;
}

function readElementHeader(bytes: Uint8Array, offset: number): ElementHeader | null {
  const idInfo = readVint(bytes, offset, true);
  if (!idInfo) return null;
  const sizeInfo = readVint(bytes, offset + idInfo.length, false);
  if (!sizeInfo) return null;
  const unknown = sizeInfo.value === Math.pow(2, 7 * sizeInfo.length) - 1;
  return {
    id: idInfo.value,
    contentStart: offset + idInfo.length + sizeInfo.length,
    contentLength: unknown ? -1 : sizeInfo.value,
  };
}

/**
 * Walks direct children of the EBML element occupying [start, end), respecting
 * each child's declared size so binary payloads (e.g. SimpleBlock frame data)
 * are skipped rather than scanned — avoiding false-positive ID matches inside
 * compressed media data.
 */
function walkChildren(
  bytes: Uint8Array,
  start: number,
  end: number,
  visitor: (id: number, contentStart: number, contentEnd: number) => void,
) {
  let offset = start;
  while (offset < end) {
    const header = readElementHeader(bytes, offset);
    if (!header) return;
    const contentEnd = header.contentLength === -1 ? end : header.contentStart + header.contentLength;
    if (contentEnd > end || header.contentStart > bytes.length) return;
    visitor(header.id, header.contentStart, Math.min(contentEnd, bytes.length));
    if (header.contentLength === -1) return; // unknown-size element consumes the rest of the range
    offset = contentEnd;
  }
}

/**
 * Locates a top-level (Level 0) element by ID, skipping siblings using their
 * declared size. Used to find the Segment element after the EBML header.
 */
function findTopLevel(bytes: Uint8Array, targetId: number): ElementHeader | null {
  let offset = 0;
  while (offset < bytes.length) {
    const header = readElementHeader(bytes, offset);
    if (!header) return null;
    if (header.id === targetId) return header;
    if (header.contentLength === -1) return null;
    offset = header.contentStart + header.contentLength;
  }
  return null;
}

/**
 * Walks the Segment content as a flat stream rather than nested [start, end)
 * ranges. This is required because MediaRecorder's chunked/timesliced output
 * (recorder.start(timeslice)) writes the Segment — and every Cluster inside
 * it — with EBML "unknown size", since the muxer can't know final sizes while
 * still recording. Per the EBML spec, an unknown-size element implicitly ends
 * as soon as an element that couldn't be its child is encountered; here that
 * means a new Cluster ID always closes any previously open Cluster, which a
 * naive [start, end)-bounded recursive walk can't detect.
 */
function webmDuration(bytes: Uint8Array): number | null {
  let timecodeScale = 1_000_000;
  let declaredDuration: number | null = null;
  let maxTimecode = 0;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

  const segment = findTopLevel(bytes, SEGMENT_ID);
  if (!segment) return null;
  const segEnd = segment.contentLength === -1 ? bytes.length : segment.contentStart + segment.contentLength;

  let offset = segment.contentStart;
  let inCluster = false;
  let clusterEnd = -1; // -1 while the open cluster's size is unknown
  let clusterTimecode = 0;

  while (offset < segEnd) {
    if (inCluster && clusterEnd !== -1 && offset >= clusterEnd) inCluster = false;

    const header = readElementHeader(bytes, offset);
    if (!header) break;

    if (header.id === CLUSTER_ID) {
      inCluster = true;
      clusterTimecode = 0;
      clusterEnd = header.contentLength === -1 ? -1 : header.contentStart + header.contentLength;
      offset = header.contentStart;
      continue;
    }

    if (header.id === INFO_ID && !inCluster) {
      const infoEnd = header.contentLength === -1 ? segEnd : header.contentStart + header.contentLength;
      walkChildren(bytes, header.contentStart, infoEnd, (infoId, iStart, iEnd) => {
        if (infoId === TIMECODE_SCALE_ID) {
          const value = readUnsigned(bytes, iStart, iEnd - iStart);
          if (value) timecodeScale = value;
        } else if (infoId === DURATION_ID) {
          const len = iEnd - iStart;
          if (len === 4) declaredDuration = view.getFloat32(iStart, false);
          else if (len === 8) declaredDuration = view.getFloat64(iStart, false);
        }
      });
      offset = infoEnd;
      continue;
    }

    if (inCluster && header.id === TIMECODE_ID && header.contentLength !== -1) {
      const value = readUnsigned(bytes, header.contentStart, header.contentLength);
      if (value != null) {
        clusterTimecode = value;
        maxTimecode = Math.max(maxTimecode, value);
      }
      offset = header.contentStart + header.contentLength;
      continue;
    }

    if (inCluster && header.id === SIMPLE_BLOCK_ID && header.contentLength !== -1) {
      const clStart = header.contentStart;
      const clEnd = header.contentStart + header.contentLength;
      const track = readVint(bytes, clStart);
      if (track && clStart + track.length + 2 <= clEnd) {
        const relative = view.getInt16(clStart + track.length, false);
        maxTimecode = Math.max(maxTimecode, clusterTimecode + relative);
      }
      offset = clEnd;
      continue;
    }

    // Unrecognized element: skip it using its declared size. An unknown-size
    // element we don't understand can't be safely skipped, so stop here.
    if (header.contentLength === -1) break;
    offset = header.contentStart + header.contentLength;
  }

  const ticks = declaredDuration && declaredDuration > 0 ? declaredDuration : maxTimecode;
  return ticks > 0 ? ticks * timecodeScale / 1_000_000_000 : null;
}

function wavDuration(bytes: Uint8Array): number | null {
  if (bytes.length < 44 || ascii(bytes, 0, 4) !== 'RIFF' || ascii(bytes, 8, 4) !== 'WAVE') return null;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const byteRate = view.getUint32(28, true);
  for (let i = 12; i + 8 <= bytes.length;) {
    const chunk = ascii(bytes, i, 4);
    const size = view.getUint32(i + 4, true);
    if (chunk === 'data' && byteRate > 0) return size / byteRate;
    i += 8 + size + (size % 2);
  }
  return null;
}

export function detectMediaDuration(bytes: Uint8Array, mimeType = ''): number | null {
  const mime = mimeType.toLowerCase();
  if (mime.includes('webm') || (bytes[0] === 0x1a && bytes[1] === 0x45)) {
    return webmDuration(bytes);
  }
  if (mime.includes('mp4') || mime.includes('quicktime') || ascii(bytes, 4, 4) === 'ftyp') {
    return mp4Duration(bytes);
  }
  if (mime.includes('wav') || ascii(bytes, 0, 4) === 'RIFF') return wavDuration(bytes);
  return null;
}
