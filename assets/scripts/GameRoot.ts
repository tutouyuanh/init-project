import {
    _decorator,
    Camera,
    Color,
    Component,
    Graphics,
    input,
    Input,
    KeyCode,
    Label,
    Node,
    resources,
    Sprite,
    SpriteFrame,
    UITransform,
    Vec3,
    view,
} from 'cc';
import { ANIM, AnimSpec, pad2 } from './AnimAtlas';
import { Sim } from './core/Sim';
import { Actor, GROUND_Y, WORLD_H, WORLD_W } from './core/Types';

const { ccclass } = _decorator;

interface ActorView {
    node: Node;
    sprite: Sprite;
    bar: Graphics;
}

@ccclass('GameRoot')
export class GameRoot extends Component {
    private sim = new Sim((Date.now() ^ 0x9e3779b9) >>> 0);
    private world: Node | null = null;
    private hud: Node | null = null;
    private logLabel: Label | null = null;
    private views = new Map<number, ActorView>();
    private frames = new Map<string, SpriteFrame[]>();
    private bgSprite: Sprite | null = null;

    onLoad(): void {
        view.setDesignResolutionSize(WORLD_W, WORLD_H, 4);
        this.ensureTree();
        this.preloadSprites();
        input.on(Input.EventType.KEY_DOWN, this.onKeyDown, this);
        input.on(Input.EventType.KEY_UP, this.onKeyUp, this);
    }

    onDestroy(): void {
        input.off(Input.EventType.KEY_DOWN, this.onKeyDown, this);
        input.off(Input.EventType.KEY_UP, this.onKeyUp, this);
    }

    private ensureTree(): void {
        this.world = this.node.getChildByName('World') ?? this.makeChild('World');
        this.hud = this.node.getChildByName('HUD') ?? this.makeChild('HUD');
        const bg = this.world.getChildByName('Backdrop') ?? this.makeChild('Backdrop', this.world);
        bg.setSiblingIndex(0);
        bg.setPosition(0, 20, 0);
        const ui = bg.getComponent(UITransform) ?? bg.addComponent(UITransform);
        ui.setContentSize(WORLD_W, 180);
        this.bgSprite = bg.getComponent(Sprite) ?? bg.addComponent(Sprite);

        const logNode = this.hud.getChildByName('Log') ?? this.makeChild('Log', this.hud);
        logNode.setPosition(0, WORLD_H / 2 - 24, 0);
        const lut = logNode.getComponent(UITransform) ?? logNode.addComponent(UITransform);
        lut.setContentSize(440, 24);
        this.logLabel = logNode.getComponent(Label) ?? logNode.addComponent(Label);
        this.logLabel.fontSize = 12;
        this.logLabel.lineHeight = 14;
        this.logLabel.color = new Color(201, 181, 154, 255);
        this.logLabel.overflow = Label.Overflow.CLAMP;
        this.logLabel.string = 'A hunter must hunt.';
    }

    private makeChild(name: string, parent: Node = this.node): Node {
        const n = new Node(name);
        n.addComponent(UITransform);
        parent.addChild(n);
        return n;
    }

    private preloadSprites(): void {
        resources.load('sprites/world/backdrop', SpriteFrame, (err, sf) => {
            if (!err && sf && this.bgSprite) this.bgSprite.spriteFrame = sf;
        });
        for (const kind of Object.keys(ANIM)) {
            const anims = ANIM[kind];
            for (const anim of Object.keys(anims)) {
                const spec = anims[anim];
                const list: SpriteFrame[] = new Array(spec.n);
                this.frames.set(`${kind}/${anim}`, list);
                for (let i = 0; i < spec.n; i++) {
                    const path = `sprites/${kind}/${anim}/${pad2(i)}`;
                    resources.load(path, SpriteFrame, (err, sf) => {
                        if (!err && sf) list[i] = sf;
                    });
                }
            }
        }
    }

    private onKeyDown(e: { keyCode: number }): void {
        this.mapKey(e.keyCode, true);
        if (this.sim.pausedChoice) {
            if (e.keyCode === KeyCode.DIGIT_1) this.sim.chooseRelic(0);
            if (e.keyCode === KeyCode.DIGIT_2) this.sim.chooseRelic(1);
            if (e.keyCode === KeyCode.DIGIT_3) this.sim.chooseRelic(2);
        }
    }

    private onKeyUp(e: { keyCode: number }): void {
        this.mapKey(e.keyCode, false);
    }

    private mapKey(code: number, down: boolean): void {
        const i = this.sim.input;
        if (code === KeyCode.KEY_A || code === KeyCode.ARROW_LEFT) i.left = down;
        if (code === KeyCode.KEY_D || code === KeyCode.ARROW_RIGHT) i.right = down;
        if (code === KeyCode.SPACE || code === KeyCode.SHIFT_LEFT) i.dodge = down;
        if (code === KeyCode.KEY_J || code === KeyCode.KEY_Z) i.attack = down;
        if (code === KeyCode.KEY_K || code === KeyCode.KEY_X) i.gun = down;
        if (code === KeyCode.KEY_L || code === KeyCode.KEY_C) i.transform = down;
        if (code === KeyCode.KEY_E || code === KeyCode.KEY_W || code === KeyCode.ENTER) i.interact = down;
    }

    update(dt: number): void {
        this.sim.tick(Math.min(dt, 0.033));
        this.syncActors();
        if (this.logLabel) this.logLabel.string = this.sim.log[0] ?? '';
        const cam = this.node.scene?.getComponentInChildren(Camera);
        if (cam) {
            const s = this.sim.shake;
            cam.node.setPosition(s ? (Math.random() - 0.5) * s : 0, s ? (Math.random() - 0.5) * s : 0, 1000);
        }
    }

    private syncActors(): void {
        const keep = new Set<number>();
        for (const a of this.sim.actors) {
            keep.add(a.id);
            let v = this.views.get(a.id);
            if (!v) {
                const n = new Node(`${a.kind}-${a.id}`);
                const ut = n.addComponent(UITransform);
                ut.setContentSize(a.width, a.height);
                ut.setAnchorPoint(0.5, 0);
                const sprite = n.addComponent(Sprite);
                sprite.sizeMode = Sprite.SizeMode.RAW;
                const barNode = new Node('hp');
                barNode.addComponent(UITransform).setContentSize(28, 4);
                const bar = barNode.addComponent(Graphics);
                n.addChild(barNode);
                barNode.setPosition(0, a.height + 6, 0);
                this.world!.addChild(n);
                v = { node: n, sprite, bar };
                this.views.set(a.id, v);
            }
            v.node.setPosition(this.toView(a));
            v.node.setScale(a.facing, 1, 1);
            const sf = this.frameOf(a);
            if (sf) v.sprite.spriteFrame = sf;
            v.sprite.color = a.flash > 0 ? new Color(255, 180, 180, 255) : Color.WHITE;
            this.drawBar(v.bar, a);
        }
        for (const [id, v] of this.views) {
            if (!keep.has(id)) {
                v.node.destroy();
                this.views.delete(id);
            }
        }
    }

    private frameOf(a: Actor): SpriteFrame | null {
        const spec: AnimSpec | undefined = ANIM[a.kind]?.[a.anim] ?? ANIM[a.kind]?.idle;
        const list = this.frames.get(`${a.kind}/${a.anim}`) ?? this.frames.get(`${a.kind}/idle`);
        if (!spec || !list || !list.length) return null;
        const n = list.filter(Boolean).length || list.length;
        const idx = spec.loop
            ? Math.floor(a.animT * spec.fps) % n
            : Math.min(n - 1, Math.floor(a.animT * spec.fps));
        return list[idx] ?? list[0] ?? null;
    }

    private drawBar(g: Graphics, a: Actor): void {
        g.clear();
        if (a.kind === 'hunter' || a.dead) return;
        g.fillColor = new Color(26, 16, 16, 220);
        g.rect(-14, 0, 28, 3);
        g.fill();
        g.fillColor = new Color(176, 32, 40, 255);
        g.rect(-14, 0, 28 * (a.hp / a.maxHp), 3);
        g.fill();
    }

    private toView(a: Actor): Vec3 {
        return new Vec3(a.x - WORLD_W / 2, WORLD_H / 2 - GROUND_Y + (GROUND_Y - a.y), 0);
    }
}
