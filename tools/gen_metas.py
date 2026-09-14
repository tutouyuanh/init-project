#!/usr/bin/env python3
"""Write Cocos Creator 3.8 .meta files and a 2D Main.scene."""
from __future__ import annotations

import json
import uuid
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
SCENE_UUID = "2d2f792f-a40c-49bb-a189-8be7d0470e15"
CANVAS_UUID = "c0c05c0c-0001-4a11-8e00-00000000c001"
GAMEROOT_SCRIPT = "c0c05c0c-0001-4a11-8e00-000000000001"


def uid(rel: str) -> str:
    if rel.replace("\\", "/") == "scripts/GameRoot.ts":
        return GAMEROOT_SCRIPT
    return str(uuid.uuid5(uuid.NAMESPACE_URL, "crimson-covenant://" + rel.replace("\\", "/")))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def dir_meta(rel: str) -> dict:
    return {
        "ver": "1.2.0",
        "importer": "directory",
        "imported": true_imported(),
        "uuid": uid(rel + "/"),
        "files": [],
        "subMetas": {},
        "userData": {},
    }


def true_imported() -> bool:
    return True


def ts_meta(rel: str) -> dict:
    return {
        "ver": "4.0.24",
        "importer": "typescript",
        "imported": True,
        "uuid": uid(rel),
        "files": [],
        "subMetas": {},
        "userData": {},
    }


def png_meta(rel: str, w: int, h: int) -> dict:
    image_uuid = uid(rel)
    sf_uuid = uid(rel + "#sf")
    pivot_y = 0.0 if any(k in rel.replace("\\", "/") for k in ("/hunter/", "/beast/", "/executioner/", "/boss/")) else 0.5
    return {
        "ver": "1.0.27",
        "importer": "image",
        "imported": True,
        "uuid": image_uuid,
        "files": [".json", ".png"],
        "subMetas": {
            "6c48a": {
                "importer": "sprite-frame",
                "uuid": sf_uuid,
                "displayName": Path(rel).stem,
                "id": "6c48a",
                "name": Path(rel).stem,
                "userData": {
                    "trimType": "auto",
                    "trimThreshold": 1,
                    "rotated": False,
                    "offsetX": 0,
                    "offsetY": 0,
                    "trimX": 0,
                    "trimY": 0,
                    "width": w,
                    "height": h,
                    "rawWidth": w,
                    "rawHeight": h,
                    "borderTop": 0,
                    "borderBottom": 0,
                    "borderLeft": 0,
                    "borderRight": 0,
                    "packable": True,
                    "pixelsToUnit": 100,
                    "pivotX": 0.5,
                    "pivotY": pivot_y,
                    "meshType": 0,
                    "isUuid": True,
                    "atlasUuid": "",
                },
                "ver": "1.0.12",
                "imported": True,
                "files": [".json"],
                "subMetas": {},
            }
        },
        "userData": {
            "type": "sprite-frame",
            "fixAlphaTransparencyArtifacts": False,
            "redirect": "6c48a",
            "hasAlpha": True,
        },
    }


def json_meta(rel: str) -> dict:
    return {
        "ver": "1.0.0",
        "importer": "json",
        "imported": True,
        "uuid": uid(rel),
        "files": [".json"],
        "subMetas": {},
        "userData": {},
    }


def scene_meta() -> dict:
    return {
        "ver": "1.1.50",
        "importer": "scene",
        "imported": True,
        "uuid": SCENE_UUID,
        "files": [".json"],
        "subMetas": {},
        "userData": {},
    }


def build_scene() -> list:
    # Minimal Canvas + Camera + GameRoot 2D scene for Creator 3.8
    g = {
        "__type__": "cc.SceneGlobals",
        "ambient": {"__id__": 12},
        "shadows": {"__id__": 13},
        "_skybox": {"__id__": 14},
        "fog": {"__id__": 15},
        "octree": {"__id__": 16},
        "skin": {"__id__": 17},
        "lightProbeInfo": {"__id__": 18},
        "bakedWithStationaryMainLight": False,
        "bakedWithHighpLightmap": False,
    }
    return [
        {
            "__type__": "cc.SceneAsset",
            "_name": "Main",
            "_objFlags": 0,
            "__editorExtras__": {},
            "_native": "",
            "scene": {"__id__": 1},
        },
        {
            "__type__": "cc.Scene",
            "_name": "Main",
            "_objFlags": 0,
            "__editorExtras__": {},
            "_parent": None,
            "_children": [{"__id__": 2}],
            "_active": True,
            "_components": [],
            "_prefab": None,
            "autoReleaseAssets": False,
            "_globals": {"__id__": 11},
            "_id": SCENE_UUID,
        },
        {
            "__type__": "cc.Node",
            "_name": "Canvas",
            "_objFlags": 0,
            "__editorExtras__": {},
            "_parent": {"__id__": 1},
            "_children": [{"__id__": 3}, {"__id__": 5}],
            "_active": True,
            "_components": [{"__id__": 7}, {"__id__": 8}, {"__id__": 9}, {"__id__": 10}],
            "_prefab": None,
            "_lpos": {"__type__": "cc.Vec3", "x": 240, "y": 135, "z": 0},
            "_lrot": {"__type__": "cc.Quat", "x": 0, "y": 0, "z": 0, "w": 1},
            "_lscale": {"__type__": "cc.Vec3", "x": 1, "y": 1, "z": 1},
            "_mobility": 0,
            "_layer": 33554432,
            "_euler": {"__type__": "cc.Vec3", "x": 0, "y": 0, "z": 0},
            "_id": "canvas-node",
        },
        {
            "__type__": "cc.Node",
            "_name": "Camera",
            "_objFlags": 0,
            "__editorExtras__": {},
            "_parent": {"__id__": 2},
            "_children": [],
            "_active": True,
            "_components": [{"__id__": 4}],
            "_prefab": None,
            "_lpos": {"__type__": "cc.Vec3", "x": 0, "y": 0, "z": 1000},
            "_lrot": {"__type__": "cc.Quat", "x": 0, "y": 0, "z": 0, "w": 1},
            "_lscale": {"__type__": "cc.Vec3", "x": 1, "y": 1, "z": 1},
            "_mobility": 0,
            "_layer": 1073741824,
            "_euler": {"__type__": "cc.Vec3", "x": 0, "y": 0, "z": 0},
            "_id": "camera-node",
        },
        {
            "__type__": "cc.Camera",
            "_name": "",
            "_objFlags": 0,
            "__editorExtras__": {},
            "node": {"__id__": 3},
            "_enabled": True,
            "__prefab": None,
            "_projection": 0,
            "_priority": 0,
            "_fov": 45,
            "_fovAxis": 0,
            "_orthoHeight": 135,
            "_near": 0,
            "_far": 2000,
            "_color": {"__type__": "cc.Color", "r": 8, "g": 7, "b": 12, "a": 255},
            "_depth": 1,
            "_stencil": 0,
            "_clearFlags": 14,
            "_rect": {"x": 0, "y": 0, "width": 1, "height": 1},
            "_aperture": 19,
            "_shutter": 7,
            "_iso": 0,
            "_screenScale": 1,
            "_visibility": 41943040,
            "_targetTexture": None,
            "_postProcess": None,
            "_usePostProcess": False,
            "_cameraType": -1,
            "_trackingType": 0,
            "_id": "camera-comp",
        },
        {
            "__type__": "cc.Node",
            "_name": "World",
            "_objFlags": 0,
            "__editorExtras__": {},
            "_parent": {"__id__": 2},
            "_children": [],
            "_active": True,
            "_components": [{"__id__": 6}],
            "_prefab": None,
            "_lpos": {"__type__": "cc.Vec3", "x": 0, "y": 0, "z": 0},
            "_lrot": {"__type__": "cc.Quat", "x": 0, "y": 0, "z": 0, "w": 1},
            "_lscale": {"__type__": "cc.Vec3", "x": 1, "y": 1, "z": 1},
            "_mobility": 0,
            "_layer": 33554432,
            "_euler": {"__type__": "cc.Vec3", "x": 0, "y": 0, "z": 0},
            "_id": "world-node",
        },
        {
            "__type__": "cc.UITransform",
            "_name": "",
            "_objFlags": 0,
            "__editorExtras__": {},
            "node": {"__id__": 5},
            "_enabled": True,
            "__prefab": None,
            "_contentSize": {"__type__": "cc.Size", "width": 480, "height": 270},
            "_anchorPoint": {"__type__": "cc.Vec2", "x": 0.5, "y": 0.5},
            "_id": "world-ut",
        },
        {
            "__type__": "cc.UITransform",
            "_name": "",
            "_objFlags": 0,
            "__editorExtras__": {},
            "node": {"__id__": 2},
            "_enabled": True,
            "__prefab": None,
            "_contentSize": {"__type__": "cc.Size", "width": 480, "height": 270},
            "_anchorPoint": {"__type__": "cc.Vec2", "x": 0.5, "y": 0.5},
            "_id": "canvas-ut",
        },
        {
            "__type__": "cc.Canvas",
            "_name": "",
            "_objFlags": 0,
            "__editorExtras__": {},
            "node": {"__id__": 2},
            "_enabled": True,
            "__prefab": None,
            "_cameraComponent": {"__id__": 4},
            "_alignCanvasWithScreen": True,
            "_id": "canvas-comp",
        },
        {
            "__type__": "cc.Widget",
            "_name": "",
            "_objFlags": 0,
            "__editorExtras__": {},
            "node": {"__id__": 2},
            "_enabled": True,
            "__prefab": None,
            "_alignFlags": 45,
            "_target": None,
            "_left": 0,
            "_right": 0,
            "_top": 0,
            "_bottom": 0,
            "_horizontalCenter": 0,
            "_verticalCenter": 0,
            "_isAbsLeft": True,
            "_isAbsRight": True,
            "_isAbsTop": True,
            "_isAbsBottom": True,
            "_isAbsHorizontalCenter": True,
            "_isAbsVerticalCenter": True,
            "_originalWidth": 0,
            "_originalHeight": 0,
            "_alignMode": 2,
            "_lockFlags": 0,
            "_id": "canvas-widget",
        },
        {
            "__type__": GAMEROOT_SCRIPT,
            "_name": "",
            "_objFlags": 0,
            "__editorExtras__": {},
            "node": {"__id__": 2},
            "_enabled": True,
            "__prefab": None,
            "_id": "gameroot-comp",
        },
        g,
        {"__type__": "cc.AmbientInfo", "_skyColorHDR": {"__type__": "cc.Vec4", "x": 0.2, "y": 0.2, "z": 0.25, "w": 0.5}, "_skyColor": {"__type__": "cc.Vec4", "x": 0.2, "y": 0.2, "z": 0.25, "w": 0.5}, "_skyIllumHDR": 20000, "_skyIllum": 20000, "_groundAlbedoHDR": {"__type__": "cc.Vec4", "x": 0.2, "y": 0.2, "z": 0.2, "w": 1}, "_groundAlbedo": {"__type__": "cc.Vec4", "x": 0.2, "y": 0.2, "z": 0.2, "w": 1}},
        {"__type__": "cc.ShadowsInfo"},
        {"__type__": "cc.SkyboxInfo"},
        {"__type__": "cc.FogInfo"},
        {"__type__": "cc.OctreeInfo"},
        {"__type__": "cc.SkinInfo"},
        {"__type__": "cc.LightProbeInfo"},
    ]


def main() -> None:
    scenes = ASSETS / "scenes"
    scenes.mkdir(parents=True, exist_ok=True)
    scene_path = scenes / "Main.scene"
    scene_path.write_text(json.dumps(build_scene(), indent=2) + "\n", encoding="utf-8")
    write_json(scenes / "Main.scene.meta", scene_meta())

    count = 1
    for path in sorted(ASSETS.rglob("*")):
        if path.name.endswith(".meta"):
            continue
        rel = str(path.relative_to(ASSETS)).replace("\\", "/")
        meta = path.with_name(path.name + ".meta")
        if path.is_dir():
            write_json(meta, dir_meta(rel))
            count += 1
            continue
        if path.suffix == ".ts":
            write_json(meta, ts_meta(rel))
        elif path.suffix == ".png":
            with Image.open(path) as im:
                w, h = im.size
            write_json(meta, png_meta(rel, w, h))
        elif path.suffix == ".json":
            write_json(meta, json_meta(rel))
        elif path.suffix == ".scene":
            continue
        else:
            continue
        count += 1

    project = ROOT / "settings" / "v2" / "packages" / "project.json"
    project.parent.mkdir(parents=True, exist_ok=True)
    write_json(
        project,
        {
            "__version__": "1.0.6",
            "general": {
                "designResolution": {"width": 480, "height": 270, "fitWidth": False, "fitHeight": True},
            },
            "custom_joint_texture_layouts": [],
        },
    )
    print(f"wrote {count} metas + Main.scene ({SCENE_UUID})")
    print(f"GameRoot script uuid {GAMEROOT_SCRIPT}")


if __name__ == "__main__":
    main()
