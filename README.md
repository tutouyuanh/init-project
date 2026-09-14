# Crimson Covenant

Ashwick 上的 2D 横版动作肉鸽。战斗手感学血缘：侧步无敌、Rally 回血、枪弹反、变形锯刃。工程给 **Cocos Creator 3.8**，也可发微信小游戏。

本仓库从 [init-project](https://github.com/tutouyuanh/init-project) 起步。原稿放在 `docs/starter-guide.md`。

## 马上能玩（不装 Creator）

本机没有装 Cocos Creator 时，用浏览器预览同一套战斗模拟：

```bash
python -m http.server 4173 --directory preview
```

打开 http://localhost:4173

| 键 | 动作 |
| --- | --- |
| A / D | 左右走 |
| J | 锯刃连段 |
| K | 火枪（对敌人起手可弹反） |
| L | 短柄 / 长柄变形，变形本身带一击 |
| Space | 侧步（无敌帧） |
| E | 休息灯笼 / 向东进下一间 |
| 1 2 3 | 遗物三选一 |

触屏设备用画面下方按钮。

## 核心循环

1. 清街（兽尸、处刑人）
2. 契约神龛三选一遗物
3. 灯笼休息回血补弹
4. 精英 → 祭坛 → **苍白讲坛** Boss

受伤后一段时间内打中敌人，会把刚掉的血 **Rally** 回来。对敌人挥刀起手时开枪，会打出 **RITE** 硬直；再补一刀触发内脏处决并回血。

## 用 Cocos Creator 打开

1. 安装 [Cocos Creator 3.8.x](https://www.cocos.com/creator-download)
2. 仪表盘 → 打开本仓库根目录
3. 打开 `assets/scenes/Main.scene`，点预览
4. 构建微信小游戏：项目 → 构建 → 微信小游戏。广告位在 `assets/scripts/WeChat.ts`

设计分辨率 **480×270**。主包资源都在 `assets/resources/sprites/`，发布前按房间再拆分包。

## 目录

```
assets/scripts/core/   引擎无关战斗模拟（预览和 Creator 共用）
assets/scripts/        GameRoot、微信钩子、动画表
assets/resources/      像素精灵、地砖、UI
assets/scenes/Main.scene
preview/               浏览器可玩切片
tools/                 精灵生成、meta 生成、打包、冒烟测试
```

重新生成像素图或 Creator 元数据：

```bash
python tools/gen_sprites.py
python tools/gen_metas.py
node tools/emit_sim.mjs
node tools/smoke_sim.mjs
```

## 已知限制

- 像素角色是程序生成的哥特剪影，不是原画。
- 本机若未安装 Creator，以 `preview/` 为可玩版本。
- 微信激励视频需要换成你的 `adUnitId`。
