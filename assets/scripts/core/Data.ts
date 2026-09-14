import { ActorKind, RelicDef, RoomDef, RunMods } from './Types';

export function defaultMods(): RunMods {
    return {
        rallyWindow: 2.4,
        dodgeIFrames: 0.2,
        dodgeCost: 22,
        shortDmg: 1,
        longDmg: 1,
        gunParryPad: 0.08,
        extraBullets: 0,
        visceralHeal: 0.4,
        moveSpeed: 1,
        emberGain: 1,
        outgoing: 1,
        incoming: 1,
        staminaRegen: 1,
        poiseIgnoreLight: false,
    };
}

export const RELICS: RelicDef[] = [
    { id: 'brooch', name: 'Cinder Brooch', desc: 'Rally window lasts longer.', tag: 'rally' },
    { id: 'quickening', name: 'Quickening Dust', desc: 'Longer i-frames, cheaper dodge.', tag: 'dodge' },
    { id: 'teeth', name: 'Serrated Creed', desc: 'Short-form saw deals more.', tag: 'saw' },
    { id: 'powder', name: 'Moon Powder', desc: 'Easier gun-rites, +1 shot.', tag: 'gun' },
    { id: 'heart', name: 'Crimson Heart', desc: 'Rites restore more blood.', tag: 'rite' },
    { id: 'stride', name: 'Tomb Stride', desc: 'Move faster through Ashwick.', tag: 'move' },
    { id: 'chalice', name: 'Echo Chalice', desc: 'Embers found +25%.', tag: 'ember' },
    { id: 'beastblood', name: 'Beast Blood', desc: 'Hit harder, bleed easier.', tag: 'risk' },
    { id: 'shawl', name: 'Iron Shawl', desc: 'Light hits cannot stagger you.', tag: 'poise' },
    { id: 'oil', name: 'Lantern Oil', desc: 'Stamina recovers quicker.', tag: 'stam' },
];

export function applyRelic(id: string, m: RunMods): void {
    switch (id) {
        case 'brooch': m.rallyWindow += 0.9; break;
        case 'quickening': m.dodgeIFrames += 0.08; m.dodgeCost -= 6; break;
        case 'teeth': m.shortDmg += 0.2; break;
        case 'powder': m.gunParryPad += 0.07; m.extraBullets += 1; break;
        case 'heart': m.visceralHeal = 0.62; break;
        case 'stride': m.moveSpeed += 0.2; break;
        case 'chalice': m.emberGain += 0.25; break;
        case 'beastblood': m.outgoing += 0.22; m.incoming += 0.12; break;
        case 'shawl': m.poiseIgnoreLight = true; break;
        case 'oil': m.staminaRegen += 0.35; break;
        default: break;
    }
}

export interface KindStats {
    hp: number;
    poise: number;
    dmg: number;
    w: number;
    h: number;
    speed: number;
    embers: number;
}

export const KIND: Record<ActorKind, KindStats> = {
    hunter: { hp: 100, poise: 40, dmg: 18, w: 22, h: 40, speed: 90, embers: 0 },
    beast: { hp: 55, poise: 28, dmg: 14, w: 36, h: 28, speed: 55, embers: 18 },
    executioner: { hp: 120, poise: 55, dmg: 22, w: 28, h: 50, speed: 38, embers: 45 },
    boss: { hp: 280, poise: 80, dmg: 26, w: 36, h: 72, speed: 32, embers: 160 },
};

export function buildRun(seed: number): RoomDef[] {
    const rng = mulberry(seed);
    const combatNames = [
        'Ashwick Lane',
        'Raincut Alley',
        'The Soot Stairs',
        'Chapel Close',
        'Ironfence Walk',
        'Gaslight Court',
    ];
    const pick = (arr: string[]) => arr[Math.floor(rng() * arr.length)];
    const rooms: RoomDef[] = [
        { type: 'start', name: 'The Quiet Manse', enemies: [] },
        { type: 'combat', name: pick(combatNames), enemies: ['beast', 'beast'] },
        { type: 'combat', name: pick(combatNames), enemies: ['beast', 'beast', 'beast'] },
        { type: 'relic', name: 'Covenant Shrine', enemies: [] },
        { type: 'combat', name: pick(combatNames), enemies: ['beast', 'executioner'] },
        { type: 'rest', name: 'Lantern Rest', enemies: [] },
        { type: 'elite', name: 'Choir Execution', enemies: ['executioner', 'beast'] },
        { type: 'relic', name: 'Blood Altar', enemies: [] },
        { type: 'boss', name: 'The Pale Pulpit', enemies: ['boss'] },
    ];
    return rooms;
}

export function mulberry(seed: number): () => number {
    let s = seed | 0;
    return () => {
        s = (s + 0x6D2B79F5) | 0;
        let t = Math.imul(s ^ (s >>> 15), 1 | s);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}
