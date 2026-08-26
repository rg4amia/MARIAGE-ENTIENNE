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

function webmDuration(bytes: Uint8Array): number | null {
  let timecodeScale = 1_000_000;
  let declaredDuration: number | null = null;
  let clusterTimecode = 0;
  let maxTimecode = 0;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);

  for (let i = 0; i + 4 < bytes.length; i++) {
    // TimecodeScale (0x2AD7B1)
    if (bytes[i] === 0x2a && bytes[i + 1] === 0xd7 && bytes[i + 2] === 0xb1) {
      const size = readVint(bytes, i + 3);
      if (size) {
        const value = readUnsigned(bytes, i + 3 + size.length, size.value);
        if (value) timecodeScale = value;
      }
    }
    // Duration (0x4489), an EBML float.
    if (bytes[i] === 0x44 && bytes[i + 1] === 0x89) {
      const size = readVint(bytes, i + 2);
      if (size) {
        const at = i + 2 + size.length;
        if (size.value === 4 && at + 4 <= bytes.length) declaredDuration = view.getFloat32(at, false);
        if (size.value === 8 && at + 8 <= bytes.length) declaredDuration = view.getFloat64(at, false);
      }
    }
    // Cluster Timecode (0xE7). This also covers MediaRecorder WebM files
    // that omit the Duration element.
    if (bytes[i] === 0xe7) {
      const size = readVint(bytes, i + 1);
      if (size && size.value <= 8) {
        const value = readUnsigned(bytes, i + 1 + size.length, size.value);
        if (value != null) {
          clusterTimecode = value;
          maxTimecode = Math.max(maxTimecode, value);
        }
      }
    }
    // SimpleBlock (0xA3): track vint, then signed 16-bit relative timecode.
    if (bytes[i] === 0xa3) {
      const size = readVint(bytes, i + 1);
      if (!size || size.value < 4) continue;
      const dataAt = i + 1 + size.length;
      const track = readVint(bytes, dataAt);
      if (!track || dataAt + track.length + 2 > bytes.length) continue;
      const relative = view.getInt16(dataAt + track.length, false);
      maxTimecode = Math.max(maxTimecode, clusterTimecode + relative);
    }
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
