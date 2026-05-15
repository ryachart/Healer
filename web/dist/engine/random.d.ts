export declare function seedFromUnknown(input: number | string | undefined): number;
export interface RandomSource {
    seed: number;
    next(): number;
}
export declare function createRandomSource(input?: number | string): RandomSource;
