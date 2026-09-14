export interface AnimSpec {
    n: number;
    fps: number;
    loop: boolean;
}

export const ANIM: Record<string, Record<string, AnimSpec>> = {
    hunter: {
        idle_short: { n: 4, fps: 6, loop: true },
        idle_long: { n: 4, fps: 6, loop: true },
        walk_short: { n: 6, fps: 10, loop: true },
        walk_long: { n: 6, fps: 10, loop: true },
        dodge: { n: 4, fps: 14, loop: false },
        attack_short_1: { n: 5, fps: 16, loop: false },
        attack_short_2: { n: 5, fps: 16, loop: false },
        attack_long: { n: 6, fps: 14, loop: false },
        transform: { n: 5, fps: 14, loop: false },
        gun: { n: 4, fps: 14, loop: false },
        visceral: { n: 6, fps: 12, loop: false },
        hurt: { n: 2, fps: 8, loop: false },
        death: { n: 4, fps: 8, loop: false },
    },
    beast: {
        idle: { n: 4, fps: 6, loop: true },
        walk: { n: 6, fps: 9, loop: true },
        swipe: { n: 5, fps: 12, loop: false },
        lunge: { n: 5, fps: 12, loop: false },
        stagger: { n: 2, fps: 6, loop: false },
        death: { n: 4, fps: 8, loop: false },
    },
    executioner: {
        idle: { n: 4, fps: 5, loop: true },
        walk: { n: 6, fps: 8, loop: true },
        slash: { n: 5, fps: 11, loop: false },
        shoot: { n: 3, fps: 8, loop: false },
        stagger: { n: 2, fps: 6, loop: false },
        death: { n: 4, fps: 7, loop: false },
    },
    boss: {
        idle: { n: 4, fps: 5, loop: true },
        slam: { n: 5, fps: 10, loop: false },
        sweep: { n: 4, fps: 10, loop: false },
        cast: { n: 3, fps: 6, loop: false },
        stagger: { n: 2, fps: 5, loop: false },
        death: { n: 4, fps: 6, loop: false },
    },
};

export function pad2(n: number): string {
    return n < 10 ? `0${n}` : `${n}`;
}
