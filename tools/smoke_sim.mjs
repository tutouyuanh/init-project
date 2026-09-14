import { Sim } from '../preview/sim.js';

const errors = [];
const fail = (msg) => {
    errors.push(msg);
    throw new Error(msg);
};

function tap(sim, key, dt = 1 / 30) {
    sim.input[key] = true;
    sim.tick(dt);
    sim.input[key] = false;
    sim.tick(dt);
}

function hold(sim, key, seconds, dt = 1 / 30) {
    sim.input[key] = true;
    for (let t = 0; t < seconds; t += dt) sim.tick(dt);
    sim.input[key] = false;
    sim.tick(dt);
}

function wait(sim, seconds, dt = 1 / 30) {
    for (let t = 0; t < seconds; t += dt) sim.tick(dt);
}

const sim = new Sim(42);
if (sim.room.type !== 'start') fail('run should open in the manse');
if (sim.hunter.hp !== 100) fail(`hunter hp ${sim.hunter.hp}`);

sim.input.right = true;
for (let i = 0; i < 600 && sim.roomIndex < 1; i++) sim.tick(1 / 30);
sim.input.right = false;
sim.tick(1 / 30);
if (sim.roomIndex < 1) {
    fail(`should walk east into first combat (index=${sim.roomIndex} x=${sim.hunter.x} clear=${sim.roomClear} type=${sim.room.type})`);
}
if (sim.room.type !== 'combat') fail(`expected combat, got ${sim.room.type}`);

const beasts = () => sim.actors.filter((a) => a.kind !== 'hunter' && !a.dead);
if (beasts().length < 1) fail('combat room has no beasts');

const freezeAi = () => {
    for (const e of beasts()) {
        e.aiCd = 99;
        e.state = 'idle';
        e.vx = 0;
        e.anim = 'idle';
    }
};

freezeAi();
let target = beasts()[0];
sim.hunter.x = target.x - 28;
sim.hunter.facing = 1;
tap(sim, 'attack');
wait(sim, 0.45);
target = sim.actors.find((a) => a.id === target.id);
if (!target || target.hp >= target.maxHp) fail('saw should deal damage');

freezeAi();
sim.hunter.hp = 60;
sim.hunter.rally = 24;
sim.hunter.rallyT = 2;
sim.hunter.state = 'idle';
sim.hunter.x = target.x - 26;
sim.hunter.facing = 1;
const hpBefore = sim.hunter.hp;
tap(sim, 'attack');
wait(sim, 0.45);
if (sim.hunter.hp <= hpBefore) fail(`rally should return blood (hp ${hpBefore} -> ${sim.hunter.hp})`);

freezeAi();
sim.hunter.state = 'idle';
const form0 = sim.hunter.form;
tap(sim, 'transform');
wait(sim, 0.5);
if (sim.hunter.form === form0) fail('transform should swap saw form');

freezeAi();
sim.hunter.bullets = 6;
sim.hunter.state = 'idle';
target = beasts()[0] || target;
if (target && !target.dead) {
    target.state = 'windup';
    target.stateT = 0.02;
    target.attackIndex = 40;
    sim.hunter.x = target.x - 28;
    sim.hunter.facing = 1;
    tap(sim, 'gun');
    wait(sim, 0.4);
    const rite = target.state === 'stagger' || sim.log.some((l) => /rite|opening/i.test(l));
    if (!rite) fail(`gun rite should stagger windup (state=${target.state} log=${sim.log[0]})`);
}

const hp2 = sim.hunter.hp;
sim.hunter.invuln = 0.25;
sim.hits.push({
    owner: 999,
    x: sim.hunter.x - 10,
    y: sim.hunter.y - 40,
    w: 40,
    h: 40,
    dmg: 40,
    poise: 10,
    knock: 10,
    kind: 'enemy',
    parry: false,
    life: 0.2,
    hit: new Set(),
});
sim.tick(1 / 30);
if (sim.hunter.hp < hp2) fail('i-frames should ignore the hit');

if (errors.length) {
    for (const e of errors) console.error('FAIL', e);
    process.exit(1);
}
console.log('smoke ok', {
    room: sim.room.name,
    index: sim.roomIndex,
    hunterHp: Math.round(sim.hunter.hp),
    form: sim.hunter.form,
    embers: sim.embers,
    log: sim.log[0],
});
