export type WeaponForm = 'short' | 'long';
export type ActorKind = 'hunter' | 'beast' | 'executioner' | 'boss';
export type RoomType = 'start' | 'combat' | 'elite' | 'rest' | 'relic' | 'boss';
export type ActorState =
    | 'idle'
    | 'walk'
    | 'attack'
    | 'dodge'
    | 'gun'
    | 'transform'
    | 'visceral'
    | 'hurt'
    | 'stagger'
    | 'windup'
    | 'recover'
    | 'cast'
    | 'dead';

export interface Vec2 {
    x: number;
    y: number;
}

export interface Rect {
    x: number;
    y: number;
    w: number;
    h: number;
}

export interface Hitbox extends Rect {
    owner: number;
    dmg: number;
    poise: number;
    knock: number;
    kind: 'melee' | 'gun' | 'visceral' | 'enemy';
    parry: boolean;
    life: number;
    hit: Set<number>;
}

export interface Projectile extends Rect {
    id: number;
    vx: number;
    vy: number;
    dmg: number;
    life: number;
    fromEnemy: boolean;
    parryable: boolean;
}

export interface Actor {
    id: number;
    kind: ActorKind;
    x: number;
    y: number;
    vx: number;
    facing: 1 | -1;
    hp: number;
    maxHp: number;
    stamina: number;
    maxStamina: number;
    poise: number;
    maxPoise: number;
    state: ActorState;
    stateT: number;
    invuln: number;
    staggerT: number;
    combo: number;
    attackIndex: number;
    anim: string;
    animT: number;
    form: WeaponForm;
    rally: number;
    rallyT: number;
    bullets: number;
    maxBullets: number;
    dead: boolean;
    flash: number;
    attackQueued: boolean;
    gunQueued: boolean;
    transformQueued: boolean;
    aiCd: number;
    pattern: number;
    phase: number;
    width: number;
    height: number;
    grounded: boolean;
}

export interface RelicDef {
    id: string;
    name: string;
    desc: string;
    tag: string;
}

export interface RunMods {
    rallyWindow: number;
    dodgeIFrames: number;
    dodgeCost: number;
    shortDmg: number;
    longDmg: number;
    gunParryPad: number;
    extraBullets: number;
    visceralHeal: number;
    moveSpeed: number;
    emberGain: number;
    outgoing: number;
    incoming: number;
    staminaRegen: number;
    poiseIgnoreLight: boolean;
}

export interface RoomDef {
    type: RoomType;
    name: string;
    enemies: ActorKind[];
}

export interface InputState {
    left: boolean;
    right: boolean;
    dodge: boolean;
    attack: boolean;
    gun: boolean;
    transform: boolean;
    interact: boolean;
}

export interface Vfx {
    kind: 'slash' | 'parry' | 'blood' | 'text';
    x: number;
    y: number;
    t: number;
    life: number;
    text?: string;
    facing?: 1 | -1;
}

export interface FloatingText {
    text: string;
    x: number;
    y: number;
    t: number;
    color: string;
}

export const GROUND_Y = 210;
export const WORLD_W = 480;
export const WORLD_H = 270;
