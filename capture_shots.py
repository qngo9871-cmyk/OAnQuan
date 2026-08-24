#!/usr/bin/env python3
"""Capture REAL in-app App Store screenshots for Ô Ăn Quan via the simulator and DEBUG
OQ_CAPTURE/OQ_LANG launch args. Adds a felt-green/gold caption band. Every shot is the
actual app UI (App Review 2.3.3). Output: screenshots/final/{en,vi}/*.png"""
import os, re, subprocess, sys, time
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

APP_DIR = Path(__file__).resolve().parent
PROJECT = APP_DIR / "OAnQuan.xcodeproj"
SCHEME = "OAnQuan"
BUNDLE = "com.quyenngo.oanquan"
W, H = 1320, 2868
BAND = 470

SHOTS = {
    "en": [
        ("01-home",    "home",    "Ô Ăn Quan —\nTraditional Vietnamese Board Game"),
        ("02-midgame", "midgame", "Sow around the loop,\ncapture across the gaps"),
        ("03-capture", "capture", "Chain captures\nempty-then-full"),
        ("04-upgrade", "upgrade", "Hard AI —\n2-ply lookahead"),
        ("05-rules",   "rules",   "Full rules,\nbuilt right in"),
    ],
    "vi": [
        ("01-home",    "home",    "Ô Ăn Quan —\nTrò Chơi Dân Gian Việt Nam"),
        ("02-midgame", "midgame", "Rải quân quanh vòng,\năn qua ô trống"),
        ("03-capture", "capture", "Ăn liên tiếp\ntrống rồi có quân"),
        ("04-upgrade", "upgrade", "AI Khó —\ntính trước 2 nước"),
        ("05-rules",   "rules",   "Luật chơi đầy đủ\nngay trong app"),
    ],
}

FONT_PATHS = ["/System/Library/Fonts/SFNSDisplay.ttf", "/System/Library/Fonts/SFNS.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf"]


def sh(*a, **k): return subprocess.run(a, check=True, capture_output=True, text=True, **k)


def find_device():
    out = subprocess.run(["xcrun", "simctl", "list", "devices", "available"],
                         capture_output=True, text=True).stdout
    for line in out.splitlines():
        m = re.search(r"^\s*(iPhone .*Pro Max)\s+\(([0-9A-F\-]{36})\)", line)
        if m:
            return m.group(2), m.group(1)
    raise SystemExit("No available 'iPhone ... Pro Max' simulator found")


def build_app():
    sh("xcodebuild", "-project", str(PROJECT), "-scheme", SCHEME, "-configuration", "Debug",
       "-sdk", "iphonesimulator", "-derivedDataPath", str(APP_DIR / "build/sim"), "build",
       cwd=str(APP_DIR))
    app = APP_DIR / "build/sim/Build/Products/Debug-iphonesimulator/OAnQuan.app"
    if not app.exists():
        raise SystemExit(f"built app not found at {app}")
    return app


def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def font(size, paths=None):
    for c in (paths or FONT_PATHS):
        if Path(c).exists():
            try: return ImageFont.truetype(c, size)
            except Exception: continue
    return ImageFont.load_default()


def compose(raw_png, headline, out_png):
    shot = Image.open(raw_png).convert("RGB").resize((W, H), Image.LANCZOS)
    canvas = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(canvas)
    top, bot = (10, 56, 34), (5, 20, 13)  # felt-green gradient, matches app icon
    for y in range(H):
        d.line([(0, y), (W, y)], fill=lerp(top, bot, y / H))
    lines = headline.split("\n")
    size = 100
    max_w = W * 0.9
    f = font(size)
    while size > 56 and max(d.textlength(line, font=f) for line in lines) > max_w:
        size -= 4
        f = font(size)
    lh = int(size * 1.18)
    y = (BAND - lh * len(lines)) // 2 + 8
    for line in lines:
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2, y), line, font=f, fill=(222, 178, 84)); y += lh
    avail_h = H - BAND - 70
    sw = int(W * 0.84); sh_ = int(shot.height * sw / shot.width)
    if sh_ > avail_h: sh_ = avail_h; sw = int(shot.width * sh_ / shot.height)
    shot = shot.resize((sw, sh_), Image.LANCZOS)
    mask = Image.new("L", (sw, sh_), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh_], radius=54, fill=255)
    px = (W - sw) // 2; py = BAND + (avail_h - sh_) // 2 + 35
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([px, py + 16, px + sw, py + sh_ + 16], radius=54, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
    canvas.paste(shot, (px, py), mask)
    canvas.save(out_png); print(f"  wrote {out_png.name}")


def main():
    DEVICE, name = find_device()
    print(f"==> device {name}")
    APP = build_app()
    subprocess.run(["xcrun", "simctl", "shutdown", DEVICE], capture_output=True)
    subprocess.run(["xcrun", "simctl", "erase", DEVICE], capture_output=True)
    subprocess.run(["xcrun", "simctl", "boot", DEVICE], capture_output=True)
    sh("xcrun", "simctl", "bootstatus", DEVICE, "-b")
    subprocess.run(["xcrun", "simctl", "status_bar", DEVICE, "override", "--time", "9:41",
                    "--batteryLevel", "100", "--batteryState", "charged",
                    "--cellularBars", "4", "--wifiBars", "3"], capture_output=True)
    sh("xcrun", "simctl", "install", DEVICE, str(APP))
    # A freshly-erased simulator can surface a first-boot system notification
    # banner ("Ready for Apple Intelligence") a few seconds in, which then
    # auto-dismisses on its own — wait it out before capturing so it doesn't
    # land in a screenshot (found via vision QA, 2026-08-24).
    time.sleep(8)
    raw = APP_DIR / "screenshots" / "_raw.png"
    for lang, shots in SHOTS.items():
        out = APP_DIR / "screenshots" / "final" / lang
        out.mkdir(parents=True, exist_ok=True)
        for shotname, cap, headline in shots:
            subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
            subprocess.run(["xcrun", "simctl", "launch", DEVICE, BUNDLE],
                           env=dict(os.environ, SIMCTL_CHILD_OQ_CAPTURE=cap, SIMCTL_CHILD_OQ_LANG=lang),
                           capture_output=True)
            # "upgrade" needs to outlast PurchaseManager.loadProduct()'s 10s
            # StoreKit timeout so productLoadFailed (and the DEBUG paywall-copy
            # override) has actually resolved by the time we screenshot —
            # otherwise this shot non-deterministically catches the loading
            # spinner instead of the real button (found via vision QA, 2026-08-24).
            time.sleep(12 if cap == "upgrade" else 2)
            sh("xcrun", "simctl", "io", DEVICE, "screenshot", str(raw))
            compose(raw, headline, out / f"{shotname}.png")
    raw.unlink(missing_ok=True)
    subprocess.run(["xcrun", "simctl", "terminate", DEVICE, BUNDLE], capture_output=True)
    print("==> done.", APP_DIR / "screenshots" / "final")


if __name__ == "__main__":
    main()
