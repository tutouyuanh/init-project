// assets/scripts/core/Data.ts
function defaultMods() {
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
    poiseIgnoreLight: false
  };
}
var RELICS = [
  { id: "brooch", name: "Cinder Brooch", desc: "Rally window lasts longer.", tag: "rally" },
  { id: "quickening", name: "Quickening Dust", desc: "Longer i-frames, cheaper dodge.", tag: "dodge" },
  { id: "teeth", name: "Serrated Creed", desc: "Short-form saw deals more.", tag: "saw" },
  { id: "powder", name: "Moon Powder", desc: "Easier gun-rites, +1 shot.", tag: "gun" },
  { id: "heart", name: "Crimson Heart", desc: "Rites restore more blood.", tag: "rite" },
  { id: "stride", name: "Tomb Stride", desc: "Move faster through Ashwick.", tag: "move" },
  { id: "chalice", name: "Echo Chalice", desc: "Embers found +25%.", tag: "ember" },
  { id: "beastblood", name: "Beast Blood", desc: "Hit harder, bleed easier.", tag: "risk" },
  { id: "shawl", name: "Iron Shawl", desc: "Light hits cannot stagger you.", tag: "poise" },
  { id: "oil", name: "Lantern Oil", desc: "Stamina recovers quicker.", tag: "stam" }
];
function applyRelic(id, m) {
  switch (id) {
    case "brooch":
      m.rallyWindow += 0.9;
      break;
    case "quickening":
      m.dodgeIFrames += 0.08;
      m.dodgeCost -= 6;
      break;
    case "teeth":
      m.shortDmg += 0.2;
      break;
    case "powder":
      m.gunParryPad += 0.07;
      m.extraBullets += 1;
      break;
    case "heart":
      m.visceralHeal = 0.62;
      break;
    case "stride":
      m.moveSpeed += 0.2;
      break;
    case "chalice":
      m.emberGain += 0.25;
      break;
    case "beastblood":
      m.outgoing += 0.22;
      m.incoming += 0.12;
      break;
    case "shawl":
      m.poiseIgnoreLight = true;
      break;
    case "oil":
      m.staminaRegen += 0.35;
      break;
    default:
      break;
  }
}
var KIND = {
  hunter: { hp: 100, poise: 40, dmg: 18, w: 22, h: 40, speed: 90, embers: 0 },
  beast: { hp: 55, poise: 28, dmg: 14, w: 36, h: 28, speed: 55, embers: 18 },
  executioner: { hp: 120, poise: 55, dmg: 22, w: 28, h: 50, speed: 38, embers: 45 },
  boss: { hp: 280, poise: 80, dmg: 26, w: 36, h: 72, speed: 32, embers: 160 }
};
function buildRun(seed) {
  const rng = mulberry(seed);
  const combatNames = [
    "Ashwick Lane",
    "Raincut Alley",
    "The Soot Stairs",
    "Chapel Close",
    "Ironfence Walk",
    "Gaslight Court"
  ];
  const pick = (arr) => arr[Math.floor(rng() * arr.length)];
  const rooms = [
    { type: "start", name: "The Quiet Manse", enemies: [] },
    { type: "combat", name: pick(combatNames), enemies: ["beast", "beast"] },
    { type: "combat", name: pick(combatNames), enemies: ["beast", "beast", "beast"] },
    { type: "relic", name: "Covenant Shrine", enemies: [] },
    { type: "combat", name: pick(combatNames), enemies: ["beast", "executioner"] },
    { type: "rest", name: "Lantern Rest", enemies: [] },
    { type: "elite", name: "Choir Execution", enemies: ["executioner", "beast"] },
    { type: "relic", name: "Blood Altar", enemies: [] },
    { type: "boss", name: "The Pale Pulpit", enemies: ["boss"] }
  ];
  return rooms;
}
function mulberry(seed) {
  let s = seed | 0;
  return () => {
    s = s + 1831565813 | 0;
    let t = Math.imul(s ^ s >>> 15, 1 | s);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}

// assets/scripts/core/Types.ts
var GROUND_Y = 210;
var WORLD_W = 480;

// assets/scripts/core/Sim.ts
var emptyInput = () => ({
  left: false,
  right: false,
  dodge: false,
  attack: false,
  gun: false,
  transform: false,
  interact: false
});
var Sim = class {
  constructor(seed = Date.now()) {
    this.rooms = [];
    this.roomIndex = 0;
    this.mods = defaultMods();
    this.relics = [];
    this.relicChoices = [];
    this.embers = 0;
    this.insight = 0;
    this.actors = [];
    this.hits = [];
    this.shots = [];
    this.vfx = [];
    this.input = emptyInput();
    this.prev = emptyInput();
    this.time = 0;
    this.hitstop = 0;
    this.shake = 0;
    this.roomClear = false;
    this.runOver = null;
    this.pausedChoice = false;
    this.nextId = 1;
    this.shotId = 1;
    this.log = [];
    this.tutorial = true;
    this.seed = seed;
    this.rng = mulberry(seed);
    this.resetRun();
  }
  resetRun() {
    this.rng = mulberry(this.seed);
    this.rooms = buildRun(this.seed);
    this.roomIndex = 0;
    this.mods = defaultMods();
    this.relics = [];
    this.relicChoices = [];
    this.embers = 0;
    this.actors = [];
    this.hits = [];
    this.shots = [];
    this.vfx = [];
    this.time = 0;
    this.hitstop = 0;
    this.shake = 0;
    this.roomClear = false;
    this.runOver = null;
    this.pausedChoice = false;
    this.nextId = 1;
    this.tutorial = true;
    this.hunter = this.spawn("hunter", 80, 1);
    this.hunter.bullets = 6;
    this.hunter.maxBullets = 6;
    this.loadRoom();
    this.note("A hunter must hunt.");
  }
  get room() {
    return this.rooms[this.roomIndex];
  }
  note(s) {
    this.log.unshift(s);
    if (this.log.length > 6) this.log.pop();
  }
  spawn(kind, x, facing) {
    const k = KIND[kind];
    const extraHp = kind === "hunter" ? 0 : Math.floor(this.roomIndex * 4);
    const a = {
      id: this.nextId++,
      kind,
      x,
      y: GROUND_Y,
      vx: 0,
      facing,
      hp: k.hp + extraHp,
      maxHp: k.hp + extraHp,
      stamina: 100,
      maxStamina: 100,
      poise: k.poise,
      maxPoise: k.poise,
      state: "idle",
      stateT: 0,
      invuln: 0,
      staggerT: 0,
      combo: 0,
      attackIndex: 0,
      anim: kind === "hunter" ? "idle_short" : "idle",
      animT: 0,
      form: "short",
      rally: 0,
      rallyT: 0,
      bullets: kind === "hunter" ? 6 : 0,
      maxBullets: kind === "hunter" ? 6 : 0,
      dead: false,
      flash: 0,
      attackQueued: false,
      gunQueued: false,
      transformQueued: false,
      aiCd: 0.4 + this.rng() * 0.6,
      pattern: 0,
      phase: 1,
      width: k.w,
      height: k.h,
      grounded: true
    };
    this.actors.push(a);
    return a;
  }
  loadRoom() {
    this.actors = this.actors.filter((a) => a.kind === "hunter");
    this.hits = [];
    this.shots = [];
    this.vfx = [];
    this.roomClear = false;
    this.pausedChoice = false;
    this.relicChoices = [];
    this.hunter.x = 70;
    this.hunter.y = GROUND_Y;
    this.hunter.vx = 0;
    this.hunter.facing = 1;
    if (this.hunter.state !== "dead") this.setState(this.hunter, "idle", 0);
    const r = this.room;
    const xs = [300, 360, 420];
    r.enemies.forEach((kind, i) => {
      var _a;
      const e = this.spawn(kind, (_a = xs[i]) != null ? _a : 340 + i * 40, -1);
      e.aiCd = 0.6 + i * 0.3;
    });
    if (r.type === "relic") this.offerRelics();
    if (r.type === "rest") this.note("Sit by the lantern. Blood stills.");
    if (r.type === "start") this.note("Walk east. J saw \xB7 K gun \xB7 L form \xB7 Space step.");
    if (r.type === "boss") this.note("The Pale Pulpit answers.");
  }
  offerRelics() {
    const owned = new Set(this.relics.map((r) => r.id));
    const pool = RELICS.filter((r) => !owned.has(r.id));
    const picks = [];
    const bag = pool.slice();
    while (picks.length < 3 && bag.length) {
      const i = Math.floor(this.rng() * bag.length);
      picks.push(bag.splice(i, 1)[0]);
    }
    this.relicChoices = picks;
    this.pausedChoice = picks.length > 0;
  }
  chooseRelic(index) {
    const r = this.relicChoices[index];
    if (!r) return;
    this.relics.push(r);
    applyRelic(r.id, this.mods);
    this.hunter.maxBullets = 6 + this.mods.extraBullets;
    this.hunter.bullets = this.hunter.maxBullets;
    this.pausedChoice = false;
    this.relicChoices = [];
    this.roomClear = true;
    this.note(`Covenant sealed: ${r.name}`);
  }
  restHeal() {
    this.hunter.hp = Math.min(this.hunter.maxHp, this.hunter.hp + this.hunter.maxHp * 0.55);
    this.hunter.bullets = this.hunter.maxBullets;
    this.hunter.rally = 0;
    this.roomClear = true;
    this.note("The lantern drinks your fear.");
  }
  pressed(key) {
    return this.input[key] && !this.prev[key];
  }
  setState(a, s, t = 0) {
    if (a.state !== s) a.animT = 0;
    a.state = s;
    a.stateT = t;
  }
  tick(dt) {
    if (this.runOver) {
      if (this.pressed("interact") || this.pressed("attack")) {
        this.seed = this.seed + 17 | 0;
        this.resetRun();
      }
      this.prev = { ...this.input };
      return;
    }
    if (this.pausedChoice) {
      this.prev = { ...this.input };
      return;
    }
    if (this.hitstop > 0) {
      this.hitstop -= dt;
      this.prev = { ...this.input };
      return;
    }
    this.time += dt;
    this.shake = Math.max(0, this.shake - dt * 8);
    this.updateHunter(dt);
    for (const a of this.actors) {
      if (a.kind !== "hunter" && !a.dead) this.updateEnemy(a, dt);
    }
    this.updatePhysics(dt);
    this.updateHits(dt);
    this.updateShots(dt);
    this.updateVfx(dt);
    this.checkRoom();
    this.prev = { ...this.input };
  }
  busy(a) {
    return a.state === "attack" || a.state === "dodge" || a.state === "gun" || a.state === "transform" || a.state === "visceral" || a.state === "hurt" || a.state === "dead" || a.state === "stagger" || a.state === "windup" || a.state === "recover" || a.state === "cast";
  }
  updateHunter(dt) {
    const h = this.hunter;
    if (h.dead) return;
    h.invuln = Math.max(0, h.invuln - dt);
    h.flash = Math.max(0, h.flash - dt);
    h.rallyT -= dt;
    if (h.rallyT <= 0) h.rally = 0;
    const regen = 38 * this.mods.staminaRegen;
    if (h.state !== "dodge" && h.state !== "attack" && h.state !== "gun") {
      h.stamina = Math.min(h.maxStamina, h.stamina + regen * dt);
    }
    if (this.pressed("attack")) h.attackQueued = true;
    if (this.pressed("gun")) h.gunQueued = true;
    if (this.pressed("transform")) h.transformQueued = true;
    if (h.state === "idle" || h.state === "walk") {
      const dir = (this.input.right ? 1 : 0) - (this.input.left ? 1 : 0);
      if (dir) {
        h.facing = dir;
        h.vx = dir * 95 * this.mods.moveSpeed;
        this.setState(h, "walk");
      } else {
        h.vx = 0;
        this.setState(h, "idle");
      }
      if (this.pressed("dodge")) this.tryDodge(h);
      else if (h.attackQueued) this.startAttack(h);
      else if (h.gunQueued) this.startGun(h);
      else if (h.transformQueued) this.startTransform(h);
      if (this.pressed("interact")) this.tryInteract();
    } else if (h.state === "dodge") {
      h.stateT += dt;
      const dur = 0.32;
      if (h.stateT >= dur) {
        h.vx *= 0.2;
        this.setState(h, "idle");
        if (h.attackQueued) this.startAttack(h);
        else if (h.gunQueued) this.startGun(h);
      }
    } else if (h.state === "attack") {
      this.advanceAttack(h, dt);
    } else if (h.state === "gun") {
      h.stateT += dt;
      if (h.stateT >= 0.08 && h.attackIndex === 0) {
        h.attackIndex = 1;
        this.fireGun(h);
      }
      if (h.stateT >= 0.38) {
        this.setState(h, "idle");
        if (h.attackQueued) this.startAttack(h);
      }
    } else if (h.state === "transform") {
      h.stateT += dt;
      if (h.stateT >= 0.12 && h.attackIndex === 0) {
        h.attackIndex = 1;
        h.form = h.form === "short" ? "long" : "short";
        this.spawnMelee(h, h.form === "long" ? 1.35 : 1.1, h.form === "long" ? 52 : 34);
        this.shake = 4;
      }
      if (h.stateT >= 0.42) this.setState(h, "idle");
    } else if (h.state === "visceral") {
      h.stateT += dt;
      if (h.stateT >= 0.12 && h.attackIndex === 0) {
        h.attackIndex = 1;
        this.spawnHit(h, 28 * h.facing, -30, 24, 34, 55 * this.mods.outgoing, 40, 40, "visceral", false, 0.12);
        const heal = Math.floor(h.maxHp * this.mods.visceralHeal);
        h.hp = Math.min(h.maxHp, h.hp + heal);
        h.rally = 0;
        this.vfx.push({ kind: "text", x: h.x, y: h.y - 50, t: 0, life: 0.8, text: `+${heal}` });
        this.shake = 7;
        this.hitstop = 0.08;
      }
      if (h.stateT >= 0.7) this.setState(h, "idle");
    } else if (h.state === "hurt") {
      h.stateT += dt;
      h.vx *= 0.9;
      if (h.stateT >= 0.28) this.setState(h, "idle");
    }
    h.attackQueued = h.attackQueued && this.busy(h);
    if (h.state === "idle" || h.state === "walk") h.attackQueued = false;
    this.syncHunterAnim(h);
  }
  tryDodge(h) {
    if (h.stamina < this.mods.dodgeCost) return;
    h.stamina -= this.mods.dodgeCost;
    const dir = (this.input.right ? 1 : 0) - (this.input.left ? 1 : 0);
    if (dir) h.facing = dir;
    h.vx = h.facing * 220;
    h.invuln = this.mods.dodgeIFrames;
    this.setState(h, "dodge");
    h.anim = "dodge";
    h.animT = 0;
  }
  startAttack(h) {
    h.attackQueued = false;
    const stam = h.form === "short" ? 12 : 18;
    if (h.stamina < stam) return;
    h.stamina -= stam;
    if (h.state === "idle" || h.state === "walk" || h.state === "dodge") h.combo = 0;
    h.attackIndex = 0;
    h.vx = h.facing * (h.form === "short" ? 30 : 18);
    this.setState(h, "attack");
    h.anim = h.form === "short" ? h.combo === 0 ? "attack_short_1" : "attack_short_2" : "attack_long";
    h.animT = 0;
  }
  advanceAttack(h, dt) {
    h.stateT += dt;
    const form = h.form;
    const combo = h.combo;
    let wind = 0.08;
    let active = 0.1;
    let rec = 0.22;
    let dmgMul = 1;
    let reach = 30;
    if (form === "short") {
      if (combo === 0) {
        wind = 0.07;
        active = 0.09;
        rec = 0.18;
        dmgMul = 1;
        reach = 32;
      } else if (combo === 1) {
        wind = 0.06;
        active = 0.1;
        rec = 0.2;
        dmgMul = 1.15;
        reach = 34;
      } else {
        wind = 0.1;
        active = 0.12;
        rec = 0.28;
        dmgMul = 1.45;
        reach = 36;
      }
    } else {
      if (combo === 0) {
        wind = 0.14;
        active = 0.12;
        rec = 0.3;
        dmgMul = 1.35;
        reach = 50;
      } else {
        wind = 0.16;
        active = 0.14;
        rec = 0.36;
        dmgMul = 1.7;
        reach = 54;
      }
    }
    dmgMul *= form === "short" ? this.mods.shortDmg : this.mods.longDmg;
    if (h.stateT >= wind && h.attackIndex === 0) {
      h.attackIndex = 1;
      this.spawnMelee(h, dmgMul, reach);
      this.vfx.push({
        kind: "slash",
        x: h.x + h.facing * (reach * 0.6),
        y: h.y - 22,
        t: 0,
        life: 0.18,
        facing: h.facing
      });
    }
    if (this.pressed("dodge") && h.stateT > wind + active) {
      this.tryDodge(h);
      return;
    }
    if (h.gunQueued && h.stateT > wind + active * 0.4) {
      this.startGun(h);
      return;
    }
    if (h.transformQueued && h.stateT > wind) {
      this.startTransform(h);
      return;
    }
    const end = wind + active + rec;
    if (h.stateT >= end) {
      if (h.attackQueued && h.combo < (form === "short" ? 2 : 1)) {
        h.combo += 1;
        h.attackIndex = 0;
        h.stateT = 0;
        h.anim = form === "short" ? h.combo === 1 ? "attack_short_2" : "attack_short_1" : "attack_long";
        h.animT = 0;
        h.attackQueued = false;
      } else {
        h.combo = 0;
        this.setState(h, "idle");
      }
    }
  }
  startGun(h) {
    h.gunQueued = false;
    if (h.bullets <= 0) {
      this.note("The flint is dry.");
      return;
    }
    h.bullets -= 1;
    h.vx *= 0.3;
    h.attackIndex = 0;
    this.setState(h, "gun");
    h.anim = "gun";
    h.animT = 0;
  }
  fireGun(h) {
    const parryPad = this.mods.gunParryPad;
    this.spawnHit(h, 36 * h.facing, -26, 46, 18, 8 * this.mods.outgoing, 24, 8, "gun", true, 0.08 + parryPad);
    this.shots.push({
      id: this.shotId++,
      x: h.x + h.facing * 18,
      y: h.y - 26,
      w: 10,
      h: 4,
      vx: h.facing * 420,
      vy: 0,
      dmg: 8,
      life: 0.28,
      fromEnemy: false,
      parryable: true
    });
  }
  startTransform(h) {
    h.transformQueued = false;
    if (h.stamina < 16) return;
    h.stamina -= 16;
    h.attackIndex = 0;
    h.vx = h.facing * 40;
    this.setState(h, "transform");
    h.anim = "transform";
    h.animT = 0;
  }
  spawnMelee(h, dmgMul, reach) {
    const dmg = KIND.hunter.dmg * dmgMul * this.mods.outgoing;
    this.spawnHit(h, reach * 0.55 * h.facing, -32, reach, 28, dmg, 14, 18, "melee", false, 0.1);
  }
  spawnHit(owner, ox, oy, w, h, dmg, poise, knock, kind, parry, life) {
    this.hits.push({
      owner: owner.id,
      x: owner.x + ox - w / 2,
      y: owner.y + oy,
      w,
      h,
      dmg,
      poise,
      knock,
      kind,
      parry,
      life,
      hit: /* @__PURE__ */ new Set()
    });
  }
  tryInteract() {
    const r = this.room;
    if (r.type === "rest" && !this.roomClear) {
      this.restHeal();
      return;
    }
    if (this.roomClear && this.hunter.x > WORLD_W - 90) this.advanceRoom();
  }
  updateEnemy(a, dt) {
    a.invuln = Math.max(0, a.invuln - dt);
    a.flash = Math.max(0, a.flash - dt);
    a.aiCd -= dt;
    const h = this.hunter;
    const dx = h.x - a.x;
    if (Math.abs(dx) > 8 && a.state !== "stagger" && a.state !== "hurt" && a.state !== "windup" && a.state !== "attack") {
      a.facing = dx > 0 ? 1 : -1;
    }
    if (a.hp < a.maxHp * 0.5) a.phase = 2;
    if (a.state === "stagger") {
      a.stateT += dt;
      a.vx *= 0.85;
      if (a.stateT >= a.staggerT) this.setState(a, "idle");
      a.anim = "stagger";
      return;
    }
    if (a.state === "hurt") {
      a.stateT += dt;
      a.vx *= 0.9;
      if (a.stateT >= 0.22) this.setState(a, "idle");
      return;
    }
    if (a.state === "windup") {
      a.stateT += dt;
      a.vx = 0;
      a.flash = a.stateT > 0.12 ? 0.05 : 0;
      if (a.stateT >= a.attackIndex / 100) {
        this.setState(a, "attack");
        a.attackIndex = 0;
        a.anim = this.enemyAttackAnim(a);
        a.animT = 0;
      } else {
        a.anim = this.enemyAttackAnim(a);
      }
      return;
    }
    if (a.state === "attack") {
      this.advanceEnemyAttack(a, dt);
      return;
    }
    if (a.state === "recover") {
      a.stateT += dt;
      a.vx *= 0.8;
      if (a.stateT >= 0.35) this.setState(a, "idle");
      a.anim = "idle";
      return;
    }
    if (a.state === "cast") {
      a.stateT += dt;
      if (a.stateT >= 0.2 && a.attackIndex === 0) {
        a.attackIndex = 1;
        this.bossCast(a);
      }
      if (a.stateT >= 0.7) this.setState(a, "recover");
      a.anim = "cast";
      return;
    }
    const dist = Math.abs(dx);
    const range = a.kind === "beast" ? 42 : a.kind === "boss" ? 58 : 50;
    if (dist > range + 10) {
      a.vx = a.facing * KIND[a.kind].speed;
      a.state = "walk";
      a.anim = "walk";
    } else {
      a.vx = 0;
      a.state = "idle";
      a.anim = "idle";
      if (a.aiCd <= 0 && !h.dead) this.enemyTelegraph(a);
    }
  }
  enemyAttackAnim(a) {
    if (a.kind === "beast") return a.pattern === 1 ? "lunge" : "swipe";
    if (a.kind === "boss") return a.pattern === 1 ? "sweep" : a.pattern === 2 ? "cast" : "slam";
    return "slash";
  }
  enemyTelegraph(a) {
    if (a.kind === "beast") a.pattern = this.rng() < 0.45 ? 1 : 0;
    else if (a.kind === "boss") a.pattern = a.phase === 2 && this.rng() < 0.4 ? 2 : this.rng() < 0.5 ? 1 : 0;
    else a.pattern = 0;
    const wind = a.kind === "beast" ? a.pattern === 1 ? 0.38 : 0.28 : a.kind === "boss" ? 0.55 : 0.46;
    a.attackIndex = Math.floor(wind * 100);
    this.setState(a, "windup");
    a.anim = this.enemyAttackAnim(a);
    a.animT = 0;
    a.aiCd = 1.1 + this.rng() * 0.7;
    if (a.kind === "boss") a.aiCd += 0.3;
  }
  advanceEnemyAttack(a, dt) {
    a.stateT += dt;
    const t = a.stateT;
    if (a.kind === "beast" && a.pattern === 0) {
      if (t >= 0.08 && a.attackIndex === 0) {
        a.attackIndex = 1;
        this.spawnHit(a, 28 * a.facing, -18, 36, 22, KIND.beast.dmg, 12, 24, "enemy", false, 0.12);
      }
      if (t >= 0.36) this.setState(a, "recover");
    } else if (a.kind === "beast") {
      if (t < 0.12) a.vx = a.facing * 200;
      if (t >= 0.1 && a.attackIndex === 0) {
        a.attackIndex = 1;
        this.spawnHit(a, 20 * a.facing, -16, 40, 24, KIND.beast.dmg * 1.25, 16, 40, "enemy", false, 0.14);
      }
      if (t >= 0.42) this.setState(a, "recover");
    } else if (a.kind === "executioner") {
      if (t >= 0.12 && a.attackIndex === 0) {
        a.attackIndex = 1;
        this.spawnHit(a, 34 * a.facing, -28, 48, 36, KIND.executioner.dmg, 22, 36, "enemy", false, 0.14);
      }
      if (t >= 0.5) this.setState(a, "recover");
    } else if (a.kind === "boss") {
      if (a.pattern === 2) {
        this.setState(a, "cast");
        return;
      }
      if (t >= 0.14 && a.attackIndex === 0) {
        a.attackIndex = 1;
        const w = a.pattern === 1 ? 70 : 44;
        this.spawnHit(
          a,
          w * 0.45 * a.facing,
          a.pattern === 1 ? -24 : -40,
          w,
          a.pattern === 1 ? 28 : 50,
          KIND.boss.dmg * (a.pattern === 1 ? 0.9 : 1.2),
          28,
          30,
          "enemy",
          false,
          0.16
        );
        this.shake = 5;
      }
      if (t >= 0.62) this.setState(a, "recover");
    }
  }
  bossCast(a) {
    for (let i = -1; i <= 1; i++) {
      this.shots.push({
        id: this.shotId++,
        x: a.x + a.facing * 20,
        y: a.y - 50 + i * 8,
        w: 10,
        h: 10,
        vx: a.facing * (90 + Math.abs(i) * 20),
        vy: i * 18,
        dmg: 16,
        life: 2.2,
        fromEnemy: true,
        parryable: true
      });
    }
    this.note("Cinders rain.");
  }
  updatePhysics(dt) {
    for (const a of this.actors) {
      a.animT += dt;
      if (a.dead) continue;
      a.x += a.vx * dt;
      a.x = Math.max(24, Math.min(WORLD_W - 24, a.x));
      a.y = GROUND_Y;
      if (a.state === "idle" || a.state === "walk") a.vx *= 0.7;
    }
  }
  updateHits(dt) {
    for (const hb of this.hits) {
      hb.life -= dt;
      for (const a of this.actors) {
        if (a.dead || hb.hit.has(a.id) || a.id === hb.owner) continue;
        if (!this.overlaps(hb, this.body(a))) continue;
        hb.hit.add(a.id);
        this.applyHit(a, hb);
      }
    }
    this.hits = this.hits.filter((h) => h.life > 0);
  }
  updateShots(dt) {
    for (const s of this.shots) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.life -= dt;
      if (s.fromEnemy) {
        const h = this.hunter;
        if (!h.dead && h.invuln <= 0 && this.overlaps(s, this.body(h))) {
          this.damageHunter(KIND.boss.dmg * 0.6, s.vx > 0 ? 1 : -1, 20);
          s.life = 0;
        }
        for (const hb of this.hits) {
          if (hb.kind === "gun" && this.overlaps(s, hb)) {
            s.life = 0;
            this.vfx.push({ kind: "parry", x: s.x, y: s.y, t: 0, life: 0.3 });
          }
        }
      }
    }
    this.shots = this.shots.filter((s) => s.life > 0 && s.x > -20 && s.x < WORLD_W + 20);
  }
  applyHit(a, hb) {
    if (a.kind === "hunter") {
      if (a.invuln > 0) return;
      this.damageHunter(hb.dmg, hb.x + hb.w / 2 > a.x ? 1 : -1, hb.knock);
      return;
    }
    if (hb.parry && (a.state === "windup" || a.state === "attack" && a.stateT < 0.12)) {
      this.stagger(a, 1.15);
      this.vfx.push({ kind: "parry", x: a.x, y: a.y - 28, t: 0, life: 0.4 });
      this.vfx.push({ kind: "text", x: a.x, y: a.y - 56, t: 0, life: 0.7, text: "RITE" });
      this.hitstop = 0.1;
      this.shake = 6;
      this.note("The shot finds the opening.");
      return;
    }
    if (hb.kind === "visceral") {
      this.hurtEnemy(a, hb.dmg, hb.knock, true);
      return;
    }
    if (a.state === "stagger" && hb.kind === "melee") {
      this.startVisceralOn(a);
      return;
    }
    this.hurtEnemy(a, hb.dmg, hb.knock, false);
    if (hb.kind === "melee" || hb.kind === "visceral") this.rallyHeal(hb.dmg * 0.55);
  }
  startVisceralOn(a) {
    const h = this.hunter;
    h.x = a.x - h.facing * 16;
    this.setState(h, "visceral");
    h.anim = "visceral";
    h.animT = 0;
    h.attackIndex = 0;
    h.vx = 0;
    this.stagger(a, 0.75);
    this.note("A visceral rite.");
  }
  hurtEnemy(a, dmg, knock, heavy) {
    const dealt = Math.max(1, Math.round(dmg));
    a.hp -= dealt;
    a.flash = 0.08;
    a.poise -= heavy ? 40 : 12;
    a.vx = -a.facing * knock;
    this.vfx.push({ kind: "blood", x: a.x, y: a.y - 20, t: 0, life: 0.3 });
    this.vfx.push({ kind: "text", x: a.x, y: a.y - 44, t: 0, life: 0.5, text: `${dealt}` });
    this.hitstop = heavy ? 0.07 : 0.03;
    this.shake = heavy ? 5 : 2;
    if (a.hp <= 0) {
      this.kill(a);
      return;
    }
    if (a.poise <= 0) {
      this.stagger(a, 0.9);
      a.poise = a.maxPoise;
    } else if (a.state !== "windup" && a.state !== "attack" && a.state !== "stagger") {
      this.setState(a, "hurt");
      a.anim = "stagger";
    }
  }
  stagger(a, dur) {
    a.staggerT = dur;
    this.setState(a, "stagger");
    a.anim = "stagger";
    a.animT = 0;
    a.vx = -a.facing * 40;
    a.poise = a.maxPoise;
  }
  kill(a) {
    a.dead = true;
    a.hp = 0;
    this.setState(a, "dead");
    a.anim = "death";
    a.animT = 0;
    a.vx = 0;
    const gain = Math.floor(KIND[a.kind].embers * this.mods.emberGain);
    this.embers += gain;
    this.vfx.push({ kind: "text", x: a.x, y: a.y - 50, t: 0, life: 0.9, text: `+${gain}` });
    if (a.kind === "boss") this.note("The pulpit falls silent.");
  }
  damageHunter(raw, fromDir, knock) {
    const h = this.hunter;
    if (h.invuln > 0 || h.dead) return;
    if (h.state === "dodge") return;
    const dmg = Math.max(1, Math.round(raw * this.mods.incoming));
    if (this.mods.poiseIgnoreLight && dmg < 16 && (h.state === "attack" || h.state === "transform")) {
      h.hp -= Math.floor(dmg * 0.5);
    } else {
      h.hp -= dmg;
      h.vx = fromDir * knock * 2;
      h.facing = -fromDir;
      this.setState(h, "hurt");
      h.anim = "hurt";
      h.animT = 0;
    }
    h.rally += dmg;
    h.rallyT = this.mods.rallyWindow;
    h.invuln = 0.18;
    h.flash = 0.1;
    this.shake = 5;
    this.hitstop = 0.05;
    this.vfx.push({ kind: "blood", x: h.x, y: h.y - 24, t: 0, life: 0.28 });
    if (h.hp <= 0) {
      h.hp = 0;
      h.dead = true;
      this.setState(h, "dead");
      h.anim = "death";
      this.runOver = "dead";
      this.note("You died. The manse remembers.");
    }
  }
  rallyHeal(amount) {
    const h = this.hunter;
    if (h.rally <= 0 || h.rallyT <= 0) return;
    const rec = Math.min(h.rally, amount);
    h.hp = Math.min(h.maxHp, h.hp + rec);
    h.rally -= rec;
    this.vfx.push({ kind: "text", x: h.x, y: h.y - 48, t: 0, life: 0.45, text: `+${Math.round(rec)}` });
  }
  body(a) {
    return { x: a.x - a.width / 2, y: a.y - a.height, w: a.width, h: a.height };
  }
  overlaps(a, b) {
    return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
  }
  updateVfx(dt) {
    for (const v of this.vfx) v.t += dt;
    this.vfx = this.vfx.filter((v) => v.t < v.life);
  }
  checkRoom() {
    if (this.pausedChoice || this.runOver) return;
    const r = this.room;
    if (!this.roomClear) {
      if (r.type === "start") this.roomClear = true;
      if (r.type === "combat" || r.type === "elite" || r.type === "boss") {
        const alive = this.actors.some((a) => a.kind !== "hunter" && !a.dead);
        if (!alive && this.actors.some((a) => a.kind !== "hunter")) {
          this.roomClear = true;
          if (r.type === "boss") {
            this.runOver = "win";
            this.insight += 1;
            this.note("Night yields. The covenant holds.");
          } else {
            this.note("The street goes quiet. Walk east.");
          }
        }
      }
    }
    if (this.roomClear && this.hunter.x > WORLD_W - 70 && !this.runOver) this.advanceRoom();
  }
  advanceRoom() {
    if (this.roomIndex >= this.rooms.length - 1) return;
    this.roomIndex += 1;
    this.loadRoom();
  }
  syncHunterAnim(h) {
    if (h.state === "idle") h.anim = h.form === "short" ? "idle_short" : "idle_long";
    if (h.state === "walk") h.anim = h.form === "short" ? "walk_short" : "walk_long";
    if (h.state === "dodge") h.anim = "dodge";
  }
  animFrame(a, count, fps, loop) {
    const f = Math.floor(a.animT * fps);
    return loop ? f % count : Math.min(count - 1, f);
  }
};
export {
  Sim
};
