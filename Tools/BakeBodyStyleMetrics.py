"""Rebuild body shading metadata after editing sprites.
Usage: python BakeBodyStyleMetrics.py PATH_TO_GODOT_PROJECT
Requires numpy, Pillow and scipy. Does not change PNG inputs.
"""
from pathlib import Path
import sys
import json
import re
import numpy as np
from PIL import Image
from scipy import ndimage

workspace = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
original = workspace / 'Hcxmmx_Hollow_Knight_Skin/Scripts'
resources = set()
for scene in ['PureVessel.tscn', 'hollow_knight.tscn']:
    source = (workspace / 'Hcxmmx_Hollow_Knight_Skin/Scenes' / scene).read_text(encoding='utf-8')
    resources.update(re.findall(r'path="(res://[^"]+\.png)"', source))
source = (original / 'BakedAnimationAssets.gd').read_text(encoding='utf-8')
resources.update(re.findall(r'preload\("(res://[^"]+\.png)"\)', source))
result = {}
for resource in sorted(resources):
    if not any(folder in resource for folder in ['/Knight_Body/', '/Prime_Body/', '/SeniorLifecycle/', '/KnightLifecycle/']):
        continue
    pixels = np.asarray(Image.open(workspace / resource.removeprefix('res://')).convert('RGBA'))
    rgb = pixels[..., :3].astype(np.float32) / 255.0
    alpha = pixels[..., 3] > 225
    ys, xs = np.where(pixels[..., 3] > 0)
    bounds = [0, 0, pixels.shape[1], pixels.shape[0]]
    if len(xs):
        bounds = [int(xs.min()), int(ys.min()), int(xs.max()-xs.min()+1), int(ys.max()-ys.min()+1)]
    labels, count = ndimage.label((rgb.min(axis=2) > .79) & alpha)
    face = [0, 0, 1, 1]
    face_valid = False
    if count:
        areas = np.bincount(labels.ravel())
        areas[0] = 0
        largest = int(areas.argmax())
        ys, xs = np.where(labels == largest)
        face = [int(xs.min()), int(ys.min()), int(xs.max()-xs.min()+1), int(ys.max()-ys.min()+1)]
        face_valid = int(areas[largest]) > max(100, int(alpha.sum() * .055))
    lum = rgb @ np.array([.2126, .7152, .0722])
    ys, xs = np.where((lum > .18) & (lum < .74) & alpha)
    cloth = [0, 0, pixels.shape[1], pixels.shape[0]]
    if len(xs) > 100:
        x0, x1 = np.quantile(xs, [.02, .98])
        y0, y1 = np.quantile(ys, [.02, .98])
        cloth = [float(x0), float(y0), max(float(x1-x0),1), max(float(y1-y0),1)]
    result[resource] = {'bounds': bounds, 'face': face, 'face_valid': face_valid, 'cloth': cloth}
(original / 'BodyStyleMetrics.gd').write_text('extends RefCounted\n\n# Offline body-frame measurements; no GPU readback during combat.\nconst FRAMES = ' + json.dumps(result, ensure_ascii=False).replace(': true', ': true').replace(': false', ': false') + '\n', encoding='utf-8')

print('Baked body shading metadata:', len(result), 'frames')
