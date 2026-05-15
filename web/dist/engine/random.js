const UINT32_MAX = 0x100000000;
export function seedFromUnknown(input) {
    if (typeof input === "number" && Number.isFinite(input)) {
        return input >>> 0;
    }
    const text = input === undefined ? "healer" : String(input);
    let hash = 2166136261;
    for (let index = 0; index < text.length; index += 1) {
        hash ^= text.charCodeAt(index);
        hash = Math.imul(hash, 16777619);
    }
    return hash >>> 0;
}
export function createRandomSource(input) {
    let state = seedFromUnknown(input);
    if (state === 0) {
        state = 0x6d2b79f5;
    }
    return {
        seed: state >>> 0,
        next() {
            state = (state + 0x6d2b79f5) >>> 0;
            let t = Math.imul(state ^ (state >>> 15), state | 1);
            t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
            return ((t ^ (t >>> 14)) >>> 0) / UINT32_MAX;
        },
    };
}
//# sourceMappingURL=random.js.map