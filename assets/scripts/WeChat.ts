/** Thin WeChat minigame hooks. Safe no-ops outside wx. */

export function wxShare(title = 'Crimson Covenant'): void {
    const w = (globalThis as { wx?: { shareAppMessage: (o: object) => void } }).wx;
    w?.shareAppMessage({ title, imageUrl: '' });
}

export function wxVibrate(): void {
    const w = (globalThis as { wx?: { vibrateShort: (o: object) => void } }).wx;
    w?.vibrateShort({ type: 'medium' });
}

export function wxShowAd(done: () => void): void {
    const w = (globalThis as { wx?: { createRewardedVideoAd?: (o: object) => { show: () => Promise<void>; onClose: (cb: (r: { isEnded: boolean }) => void) => void } } }).wx;
    if (!w?.createRewardedVideoAd) {
        done();
        return;
    }
    const ad = w.createRewardedVideoAd({ adUnitId: 'your-ad-unit-id' });
    ad.onClose((r) => {
        if (r.isEnded) done();
    });
    ad.show().catch(() => done());
}
