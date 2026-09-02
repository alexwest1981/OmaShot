#!/usr/bin/env python3
"""
OmaShot / Screenshot Manager for Omarchy
Manages screenshot history, metadata extraction, editing, copying, and global system integration.
Maintains symlinks for AI agents (Claude, Gemini, Antigravity) at ~/Pictures/latest-screenshot.png
"""

import sys
import os
import glob
import json
import struct
import subprocess
import argparse
import shutil
from datetime import datetime

PICTURES_DIR = os.path.expanduser("~/Pictures")
SCREENSHOTS_DIR = os.path.expanduser("~/Pictures/Screenshots")
LATEST_SYMLINK = os.path.join(PICTURES_DIR, "latest-screenshot.png")
TMP_SYMLINK = "/tmp/latest-screenshot.png"
METADATA_CACHE = os.path.expanduser("~/.cache/omashot-latest.json")

def format_file_size(size_bytes):
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f} KB"
    else:
        return f"{size_bytes / (1024 * 1024):.1f} MB"

def get_image_dimensions(filepath):
    try:
        with open(filepath, "rb") as f:
            head = f.read(32)
            if head.startswith(b"\x89PNG\r\n\x1a\n"):
                w, h = struct.unpack(">LL", head[16:24])
                return w, h
            elif head.startswith(b"\xff\xd8"):
                # Fast JPEG dimension probe
                f.seek(0)
                f.read(2)
                b = f.read(1)
                while b:
                    while b != b"\xff":
                        b = f.read(1)
                    while b == b"\xff":
                        b = f.read(1)
                    if b >= b"\xc0" and b <= b"\xc3":
                        f.read(3)
                        h, w = struct.unpack(">HH", f.read(4))
                        return w, h
                    else:
                        data = f.read(2)
                        if len(data) < 2:
                            break
                        f.read(struct.unpack(">H", data)[0] - 2)
                    b = f.read(1)
    except Exception:
        pass
    return 0, 0

def format_relative_date(mtime):
    dt = datetime.fromtimestamp(mtime)
    now = datetime.now()
    diff = (now - dt).total_seconds()
    
    if diff < 60:
        return "Nyss"
    elif diff < 3600:
        mins = int(diff / 60)
        return f"{mins} min sedan"
    elif dt.date() == now.date():
        return f"Idag {dt.strftime('%H:%M')}"
    elif (now.date() - dt.date()).days == 1:
        return f"Igår {dt.strftime('%H:%M')}"
    elif dt.year == now.year:
        months = ["jan", "feb", "mar", "apr", "maj", "jun", "jul", "aug", "sep", "okt", "nov", "dec"]
        return f"{dt.day} {months[dt.month-1]} {dt.strftime('%H:%M')}"
    else:
        return dt.strftime("%Y-%m-%d %H:%M")

def update_system_symlinks(latest_path, metadata):
    if not latest_path or not os.path.exists(latest_path):
        return
    try:
        if os.path.islink(LATEST_SYMLINK) or os.path.exists(LATEST_SYMLINK):
            os.remove(LATEST_SYMLINK)
        os.symlink(latest_path, LATEST_SYMLINK)
    except Exception:
        pass

    try:
        if os.path.islink(TMP_SYMLINK) or os.path.exists(TMP_SYMLINK):
            os.remove(TMP_SYMLINK)
        os.symlink(latest_path, TMP_SYMLINK)
    except Exception:
        pass

    try:
        os.makedirs(os.path.dirname(METADATA_CACHE), exist_ok=True)
        with open(METADATA_CACHE, "w", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)
    except Exception:
        pass

def scan_screenshots():
    patterns = [
        os.path.join(PICTURES_DIR, "screenshot-*.png"),
        os.path.join(PICTURES_DIR, "screenshot-*.jpg"),
        os.path.join(PICTURES_DIR, "Screenshot_*.png"),
        os.path.join(PICTURES_DIR, "*.png"),
        os.path.join(SCREENSHOTS_DIR, "*.png"),
        os.path.join(SCREENSHOTS_DIR, "*.jpg")
    ]
    
    found_paths = set()
    for p in patterns:
        for fpath in glob.glob(p):
            if os.path.islink(fpath):
                continue
            if os.path.isfile(fpath) and not os.path.basename(fpath).startswith("."):
                found_paths.add(os.path.abspath(fpath))
                
    files_with_stats = []
    for fpath in found_paths:
        try:
            stat = os.stat(fpath)
            files_with_stats.append((fpath, stat.st_mtime, stat.st_size))
        except Exception:
            continue
            
    files_with_stats.sort(key=lambda x: x[1], reverse=True)
    
    items = []
    for fpath, mtime, size_bytes in files_with_stats[:60]:
        w, h = get_image_dimensions(fpath)
        dim_str = f"{w} × {h} px" if w > 0 and h > 0 else ""
        items.append({
            "path": fpath,
            "filename": os.path.basename(fpath),
            "uri": f"file://{fpath}",
            "size_bytes": size_bytes,
            "size_human": format_file_size(size_bytes),
            "width": w,
            "height": h,
            "dimensions": dim_str,
            "mtime": int(mtime),
            "relative_time": format_relative_date(mtime),
            "date_human": datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
        })
        
    latest_item = items[0] if items else None
    if latest_item:
        update_system_symlinks(latest_item["path"], latest_item)
        
    return {
        "ok": True,
        "total_count": len(files_with_stats),
        "latest": latest_item,
        "history": items,
        "latest_symlink": LATEST_SYMLINK,
        "tmp_symlink": TMP_SYMLINK
    }

def capture_screenshot(mode="smart"):
    # mode: smart | region | window | fullscreen
    cmd_map = {
        "smart": ["omarchy-capture-screenshot", "smart"],
        "region": ["omarchy-capture-screenshot", "region"],
        "window": ["omarchy-capture-screenshot", "windows"],
        "fullscreen": ["omarchy-capture-screenshot", "fullscreen"]
    }
    cmd = cmd_map.get(mode, ["omarchy-capture-screenshot", "smart"])
    
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        return scan_screenshots()
    except Exception as e:
        return {"ok": False, "error": str(e)}

def copy_to_clipboard(filepath, mode="path"):
    if not os.path.exists(filepath):
        return {"ok": False, "error": "Filen finns inte"}
        
    if mode == "image":
        try:
            with open(filepath, "rb") as f:
                subprocess.run(["wl-copy", "--type", "image/png"], stdin=f, check=True)
            return {"ok": True, "message": "Bild kopierad till urklipp"}
        except Exception as e:
            return {"ok": False, "error": str(e)}
    else:
        try:
            subprocess.run(["wl-copy"], input=filepath.encode("utf-8"), check=True)
            return {"ok": True, "message": "Sökväg kopierad till urklipp"}
        except Exception as e:
            return {"ok": False, "error": str(e)}

def open_editor(filepath):
    if not os.path.exists(filepath):
        return {"ok": False, "error": "Filen finns inte"}
    
    if shutil.which("tensaku-edit"):
        subprocess.Popen(["tensaku-edit", filepath])
        return {"ok": True, "app": "tensaku-edit"}
    elif shutil.which("pinta"):
        subprocess.Popen(["pinta", filepath])
        return {"ok": True, "app": "pinta"}
    else:
        subprocess.Popen(["xdg-open", filepath])
        return {"ok": True, "app": "xdg-open"}

def open_viewer(filepath):
    if not os.path.exists(filepath):
        return {"ok": False, "error": "Filen finns inte"}
    
    if shutil.which("imv"):
        subprocess.Popen(["imv", filepath])
        return {"ok": True, "app": "imv"}
    else:
        subprocess.Popen(["xdg-open", filepath])
        return {"ok": True, "app": "xdg-open"}

def delete_screenshot(filepath):
    if not os.path.exists(filepath):
        return {"ok": False, "error": "Filen finns inte"}
    try:
        os.remove(filepath)
        return scan_screenshots()
    except Exception as e:
        return {"ok": False, "error": str(e)}

def main():
    parser = argparse.ArgumentParser(description="OmaShot Screenshot Manager")
    parser.add_argument("--list", action="store_true", help="List screenshots with metadata")
    parser.add_argument("--capture", type=str, choices=["smart", "region", "window", "fullscreen"], help="Take a screenshot")
    parser.add_argument("--copy-path", type=str, help="Copy filepath to clipboard")
    parser.add_argument("--copy-image", type=str, help="Copy image bytes to clipboard")
    parser.add_argument("--edit", type=str, help="Open image in editor (tensaku/pinta)")
    parser.add_argument("--view", type=str, help="Open image in viewer (imv/xdg-open)")
    parser.add_argument("--delete", type=str, help="Delete screenshot file")
    
    args = parser.parse_args()
    
    if args.capture:
        print(json.dumps(capture_screenshot(args.capture), ensure_ascii=False))
    elif args.copy_path:
        print(json.dumps(copy_to_clipboard(args.copy_path, mode="path"), ensure_ascii=False))
    elif args.copy_image:
        print(json.dumps(copy_to_clipboard(args.copy_image, mode="image"), ensure_ascii=False))
    elif args.edit:
        print(json.dumps(open_editor(args.edit), ensure_ascii=False))
    elif args.view:
        print(json.dumps(open_viewer(args.view), ensure_ascii=False))
    elif args.delete:
        print(json.dumps(delete_screenshot(args.delete), ensure_ascii=False))
    else:
        print(json.dumps(scan_screenshots(), ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
