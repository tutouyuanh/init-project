import { Sim } from './sim.js';

const W = 480;
const H = 270;
const GROUND = 210;

const canvas = document.getElementById('game');
const ctx = canvas.getContext('2d');
ctx.imageSmoothingEnabled = false;

const logEl = document.getElementById('log');
const metaEl = document.getElementById('runMeta');

const sim = new Sim((Math.random() * 1e9) | 0);
const images = new Map();
const sheets = new Map();

const ANIM = {
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

function loadImg(src) {
  return new Promise((resolve) => {
    const im = new Image();
    im.onload = () => resolve(im);
    im.onerror = () => resolve(null);
    im.src = src;
  });
}

async function boot() {
  const jobs = [];
  const add = (key, src) => {
    jobs.push(loadImg(src).then((im) => im && images.set(key, im)));
  };
  add('backdrop', './img/backdrop.png');
  add('cobble', './img/cobble.png');
  add('brick', './img/brick.png');
  add('lantern', './img/lantern.png');
  add('fence', './img/fence.png');
  add('slash', './img/fx_slash.png');
  add('parry', './img/fx_parry.png');
  add('blood', './img/fx_blood.png');

  for (const [kind, anims] of Object.entries(ANIM)) {
    for (const [anim, spec] of Object.entries(anims)) {
      const frames = await Promise.all(
        Array.from({ length: spec.n }, (_, i) =>
          loadImg(`./img/${kind}/${anim}/${String(i).padStart(2, '0')}.png`),
        ),
      );
      sheets.set(`${kind}/${anim}`, frames.filter(Boolean));
    }
  }
  await Promise.all(jobs);
  requestAnimationFrame(loop);
}

const keys = sim.input;
window.addEventListener('keydown', (e) => {
  bind(e.code, true);
  if (['Space', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(e.code)) e.preventDefault();
});
window.addEventListener('keyup', (e) => bind(e.code, false));

function bind(code, down) {
  if (code === 'KeyA' || code === 'ArrowLeft') keys.left = down;
  if (code === 'KeyD' || code === 'ArrowRight') keys.right = down;
  if (code === 'Space' || code === 'ShiftLeft') keys.dodge = down;
  if (code === 'KeyJ' || code === 'KeyZ') keys.attack = down;
  if (code === 'KeyK' || code === 'KeyX') keys.gun = down;
  if (code === 'KeyL' || code === 'KeyC') keys.transform = down;
  if (code === 'KeyE' || code === 'KeyW' || code === 'Enter') keys.interact = down;
  if (sim.pausedChoice && down) {
    if (code === 'Digit1') sim.chooseRelic(0);
    if (code === 'Digit2') sim.chooseRelic(1);
    if (code === 'Digit3') sim.chooseRelic(2);
  }
}

for (const btn of document.querySelectorAll('#pads button')) {
  const k = btn.getAttribute('data-k');
  const press = (d) => {
    keys[k] = d;
  };
  btn.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    press(true);
  });
  btn.addEventListener('pointerup', () => press(false));
  btn.addEventListener('pointercancel', () => press(false));
  btn.addEventListener('pointerleave', () => press(false));
}

let last = performance.now();
function loop(now) {
  const dt = Math.min(0.033, (now - last) / 1000);
  last = now;
  sim.tick(dt);
  draw();
  requestAnimationFrame(loop);
}

function frameOf(a) {
  const spec = ANIM[a.kind]?.[a.anim] || ANIM[a.kind]?.idle || ANIM.hunter.idle_short;
  const list = sheets.get(`${a.kind}/${a.anim}`) || sheets.get(`${a.kind}/idle`) || [];
  if (!list.length) return null;
  const n = list.length;
  const fps = spec.fps || 8;
  const f = spec.loop ? Math.floor(a.animT * fps) % n : Math.min(n - 1, Math.floor(a.animT * fps));
  return list[f];
}

function draw() {
  const shakeX = sim.shake ? (Math.random() - 0.5) * sim.shake : 0;
  const shakeY = sim.shake ? (Math.random() - 0.5) * sim.shake : 0;
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, W, H);
  ctx.translate(shakeX, shakeY);

  const bg = images.get('backdrop');
  if (bg) ctx.drawImage(bg, 0, 0, W, 180);
  else {
    ctx.fillStyle = '#0d0c14';
    ctx.fillRect(0, 0, W, H);
  }

  const brick = images.get('brick');
  if (brick) {
    for (let x = 0; x < W; x += 32) {
      ctx.drawImage(brick, x, 148, 32, 32);
      ctx.drawImage(brick, x, 116, 32, 32);
    }
  }

  const cobble = images.get('cobble');
  if (cobble) {
    for (let y = GROUND; y < H; y += 32) {
      for (let x = 0; x < W; x += 32) ctx.drawImage(cobble, x, y, 32, 32);
    }
  } else {
    ctx.fillStyle = '#241e2a';
    ctx.fillRect(0, GROUND, W, H - GROUND);
  }

  const fence = images.get('fence');
  if (fence) {
    for (let x = 20; x < 200; x += 46) ctx.drawImage(fence, x, GROUND - 40);
  }
  const lantern = images.get('lantern');
  if (lantern) {
    ctx.drawImage(lantern, 40, GROUND - 64);
    ctx.drawImage(lantern, 400, GROUND - 64);
  }

  ctx.fillStyle = 'rgba(20,22,36,0.18)';
  ctx.fillRect(0, GROUND - 20, W, 20);

  for (const a of sim.actors) drawActor(a);
  for (const s of sim.shots) {
    ctx.fillStyle = s.fromEnemy ? '#c69a3e' : '#f2e6c4';
    ctx.fillRect(s.x, s.y, s.w, s.h);
  }
  for (const v of sim.vfx) drawVfx(v);

  if (sim.roomClear && !sim.runOver && sim.room.type !== 'relic') {
    ctx.fillStyle = '#c69a3e';
    ctx.fillRect(W - 18, GROUND - 48, 6, 48);
    ctx.fillStyle = '#e8dcc8';
    ctx.font = '8px monospace';
    ctx.fillText('EAST', W - 40, GROUND - 54);
  }

  drawHud();
  drawModals();

  logEl.textContent = sim.log[0] || '';
  metaEl.textContent = `Night ${sim.insight + 1} · ${sim.room.name} · ${sim.embers} embers`;
}

function drawActor(a) {
  const im = frameOf(a);
  const ghost = a.invuln > 0 && a.kind === 'hunter' && Math.floor(sim.time * 30) % 2 === 0;
  ctx.save();
  ctx.translate(a.x, a.y);
  ctx.scale(a.facing, 1);
  if (a.flash > 0) ctx.globalAlpha = 0.55;
  if (ghost) ctx.globalAlpha = 0.4;
  if (im) {
    ctx.drawImage(im, -im.width / 2, -(im.height - 4));
  } else {
    ctx.fillStyle = a.kind === 'hunter' ? '#8a3030' : '#5a4a3a';
    ctx.fillRect(-a.width / 2, -a.height, a.width, a.height);
  }
  ctx.restore();

  if (a.kind !== 'hunter' && !a.dead) {
    const bw = 28;
    ctx.fillStyle = '#1a1010';
    ctx.fillRect(a.x - bw / 2, a.y - a.height - 8, bw, 3);
    ctx.fillStyle = '#b02028';
    ctx.fillRect(a.x - bw / 2, a.y - a.height - 8, (bw * a.hp) / a.maxHp, 3);
    if (a.state === 'stagger') {
      ctx.fillStyle = '#e8dcc8';
      ctx.font = '7px monospace';
      ctx.fillText('OPEN', a.x - 10, a.y - a.height - 12);
    }
    if (a.state === 'windup') {
      ctx.fillStyle = '#c69a3e';
      ctx.fillRect(a.x - 2, a.y - a.height - 14, 4, 4);
    }
  }
}

function drawVfx(v) {
  const a = 1 - v.t / v.life;
  ctx.globalAlpha = a;
  if (v.kind === 'text') {
    ctx.fillStyle = v.text && v.text.startsWith('+') ? '#d4c48a' : '#e8dcc8';
    ctx.font = '8px monospace';
    ctx.fillText(v.text, v.x - 8, v.y - v.t * 20);
  } else {
    const im = images.get(v.kind);
    if (im) {
      ctx.save();
      ctx.translate(v.x, v.y);
      if (v.facing === -1) ctx.scale(-1, 1);
      ctx.drawImage(im, -im.width / 2, -im.height / 2);
      ctx.restore();
    }
  }
  ctx.globalAlpha = 1;
}

function bar(x, y, w, h, t, back, fill) {
  ctx.fillStyle = back;
  ctx.fillRect(x, y, w, h);
  ctx.fillStyle = fill;
  ctx.fillRect(x, y, Math.max(0, w * Math.min(1, t)), h);
}

function drawHud() {
  const h = sim.hunter;
  ctx.fillStyle = 'rgba(8,6,10,0.72)';
  ctx.fillRect(8, 8, 180, 36);
  ctx.strokeStyle = '#5a4630';
  ctx.strokeRect(8.5, 8.5, 179, 35);
  bar(14, 14, 120, 8, h.hp / h.maxHp, '#2a1012', '#b02028');
  if (h.rally > 0 && h.rallyT > 0) {
    ctx.fillStyle = 'rgba(232,214,196,0.45)';
    const extra = (h.rally / h.maxHp) * 120;
    const hpw = (h.hp / h.maxHp) * 120;
    ctx.fillRect(14 + hpw, 14, Math.min(extra, 120 - hpw), 8);
  }
  bar(14, 24, 120, 5, h.stamina / h.maxStamina, '#141018', '#c69a3e');
  ctx.fillStyle = '#e8dcc8';
  ctx.font = '8px monospace';
  ctx.fillText(`HP ${Math.ceil(h.hp)}`, 138, 21);
  ctx.fillText(
    `${h.form === 'short' ? 'SAW' : 'CLEAVER'}  ${'•'.repeat(h.bullets)}${'·'.repeat(Math.max(0, h.maxBullets - h.bullets))}`,
    14,
    38,
  );

  ctx.fillStyle = '#8a7a66';
  ctx.font = '8px monospace';
  ctx.fillText(sim.room.name.toUpperCase(), W - 8 - ctx.measureText(sim.room.name.toUpperCase()).width, 16);
  const path = sim.rooms.map((r, i) => (i === sim.roomIndex ? '◆' : i < sim.roomIndex ? '●' : '○')).join('');
  ctx.fillText(path, W - 8 - ctx.measureText(path).width, 28);
}

function wrap(text, x, y, max, lh) {
  const words = text.split(' ');
  let line = '';
  let yy = y;
  for (const w of words) {
    const test = line ? `${line} ${w}` : w;
    if (ctx.measureText(test).width > max) {
      ctx.fillText(line, x, yy);
      line = w;
      yy += lh;
    } else line = test;
  }
  if (line) ctx.fillText(line, x, yy);
}

function drawModals() {
  if (sim.pausedChoice) {
    ctx.fillStyle = 'rgba(6,5,8,0.72)';
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = '#e8dcc8';
    ctx.font = '12px Trebuchet MS';
    ctx.fillText('SEAL A COVENANT', 168, 48);
    sim.relicChoices.forEach((r, i) => {
      const x = 40 + i * 140;
      const y = 70;
      ctx.fillStyle = '#120e12';
      ctx.fillRect(x, y, 128, 110);
      ctx.strokeStyle = '#c69a3e';
      ctx.strokeRect(x + 0.5, y + 0.5, 127, 109);
      ctx.fillStyle = '#c69a3e';
      ctx.font = '8px monospace';
      ctx.fillText(`[${i + 1}]`, x + 8, y + 16);
      ctx.fillStyle = '#e8dcc8';
      ctx.font = '10px Trebuchet MS';
      wrap(r.name, x + 8, y + 34, 112, 12);
      ctx.fillStyle = '#8a7a66';
      ctx.font = '8px Trebuchet MS';
      wrap(r.desc, x + 8, y + 64, 112, 10);
    });
    ctx.fillStyle = '#8a7a66';
    ctx.font = '8px monospace';
    ctx.fillText('Press 1 / 2 / 3', 188, 200);
    canvas.onclick = (ev) => {
      if (!sim.pausedChoice) return;
      const r = canvas.getBoundingClientRect();
      const x = ((ev.clientX - r.left) / r.width) * W;
      const i = Math.floor((x - 40) / 140);
      if (i >= 0 && i < sim.relicChoices.length) sim.chooseRelic(i);
    };
  } else {
    canvas.onclick = null;
  }

  if (sim.runOver) {
    ctx.fillStyle = 'rgba(6,4,6,0.78)';
    ctx.fillRect(0, 0, W, H);
    ctx.fillStyle = sim.runOver === 'win' ? '#c69a3e' : '#b02028';
    ctx.font = '18px Trebuchet MS';
    const t = sim.runOver === 'win' ? 'NIGHT YIELDS' : 'YOU DIED';
    ctx.fillText(t, (W - ctx.measureText(t).width) / 2, 120);
    ctx.fillStyle = '#e8dcc8';
    ctx.font = '10px Trebuchet MS';
    const s = `${sim.embers} embers · press J to hunt again`;
    ctx.fillText(s, (W - ctx.measureText(s).width) / 2, 148);
  }
}

boot();
