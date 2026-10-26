#!/usr/bin/env python3
"""Memento mori wallpaper: one square per week of a 99-year life.

Reads like a book: left to right, top to bottom, two years per row. Lived weeks
are filled, the current week is highlighted, and a progress bar on top shows how
much of the 99 years is behind you.

Birth date is read from ~/.config/memento/birthdate (YYYY-MM-DD), kept out of
the dotfiles repo on purpose. Run with --no-apply to only render the image.
"""
import datetime as dt
import glob
import os
import subprocess
import sys

YEARS = 99
WEEKS = 52
YEARS_PER_ROW = 2
WIDTH, HEIGHT = 2880, 1800

BG = "#0b0d12"
LIVED = "#4d6380"
CURRENT = "#9dbcff"
LEFT = "#1a1f29"
TEXT = "#e6edf7"
MUTED = "#6c7a90"
FONT = "JetBrains Mono"

CONFIG = os.path.expanduser("~/.config/memento/birthdate")
OUT_DIR = os.path.expanduser("~/.local/share/memento")


def read_birthdate():
    try:
        with open(CONFIG) as f:
            return dt.date.fromisoformat(f.read().strip())
    except (OSError, ValueError) as e:
        sys.exit(f"memento: put your birth date (YYYY-MM-DD) in {CONFIG} ({e})")


def render_svg(birth, today):
    total = YEARS * WEEKS
    # Whole years since birth, then weeks since the last birthday. Real years are
    # a bit over 52 weeks, so counting days // 7 would drift ahead each year.
    age = today.year - birth.year - ((today.month, today.day) < (birth.month, birth.day))
    last_birthday = birth.replace(year=birth.year + age)
    week = min(WEEKS - 1, (today - last_birthday).days // 7)
    lived = min(total, age * WEEKS + week)
    left = total - lived
    death = birth.replace(year=birth.year + YEARS)
    pct = lived / total

    total_months = YEARS * 12
    months = min(total_months, (today.year - birth.year) * 12 + today.month - birth.month
                 - (today.day < birth.day))

    rows = -(-YEARS // YEARS_PER_ROW)  # round up: 99 years -> last row is one year
    cols = WEEKS * YEARS_PER_ROW

    # Squares sized to the screen width. year_gap > 0 would separate the years in a row.
    pitch = (WIDTH * 0.9) / cols
    year_gap = 0
    size = pitch * 0.8
    radius = size * 0.2
    grid_w = cols * pitch + year_gap * (YEARS_PER_ROW - 1) - (pitch - size)
    grid_h = rows * pitch - (pitch - size)

    # Header (title, progress bar, stats) sits above the grid.
    header_h = pitch * 6.5
    x0 = (WIDTH - grid_w) / 2
    top = (HEIGHT - header_h - grid_h) / 2 + HEIGHT * 0.015  # nudge below the panel
    title_y = top + pitch * 1.4
    bar_y = title_y + pitch * 1.1
    bar_h = pitch * 0.7
    stats_y = bar_y + bar_h + pitch * 1.5
    y0 = top + header_h

    big, mid, small = pitch * 1.6, pitch * 1.0, pitch * 0.8
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}">',
        f'<rect width="100%" height="100%" fill="{BG}"/>',
        f'<g font-family="{FONT}">',
        f'<text x="{x0:.1f}" y="{title_y:.1f}" fill="{TEXT}" font-size="{big:.1f}" '
        f'letter-spacing="{pitch * 0.3:.1f}">MEMENTO MORI</text>',
        f'<text x="{x0 + grid_w:.1f}" y="{title_y:.1f}" fill="{TEXT}" font-size="{mid:.1f}" '
        f'text-anchor="end">{left:,} weeks left</text>',
        # Progress bar
        f'<rect x="{x0:.1f}" y="{bar_y:.1f}" width="{grid_w:.1f}" height="{bar_h:.1f}" '
        f'rx="{bar_h / 2:.1f}" fill="{LEFT}"/>',
        f'<rect x="{x0:.1f}" y="{bar_y:.1f}" width="{grid_w * pct:.1f}" height="{bar_h:.1f}" '
        f'rx="{bar_h / 2:.1f}" fill="{CURRENT}"/>',
        f'<text x="{x0:.1f}" y="{stats_y:.1f}" fill="{TEXT}" font-size="{small:.1f}">{pct:.1%} lived</text>',
        f'<text x="{x0 + grid_w:.1f}" y="{stats_y:.1f}" fill="{MUTED}" font-size="{small:.1f}" '
        f'text-anchor="end">{months:,} / {total_months:,} months · '
        f'{lived:,} / {total:,} weeks · {death:%b %Y}</text>',
    ]

    # Age labels down the left side every 10 years.
    for row in range(0, rows, 10 // YEARS_PER_ROW):
        y = y0 + row * pitch + size * 0.8
        parts.append(f'<text x="{x0 - pitch * 0.6:.1f}" y="{y:.1f}" fill="{MUTED}" '
                     f'font-size="{small:.1f}" text-anchor="end">{row * YEARS_PER_ROW}</text>')
    parts.append("</g>")

    for n in range(total):
        year, week = divmod(n, WEEKS)
        row, slot = divmod(year, YEARS_PER_ROW)
        x = x0 + (slot * WEEKS + week) * pitch + slot * year_gap
        y = y0 + row * pitch
        color = CURRENT if n == lived else LIVED if n < lived else LEFT
        parts.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{size:.1f}" height="{size:.1f}" '
                     f'rx="{radius:.1f}" fill="{color}"/>')

    parts.append("</svg>")
    return "\n".join(parts)


def main():
    apply = "--no-apply" not in sys.argv
    today = dt.date.today()
    svg = render_svg(read_birthdate(), today)

    os.makedirs(OUT_DIR, exist_ok=True)
    # New file name each week: KDE won't reload a wallpaper whose path didn't change.
    png = os.path.join(OUT_DIR, f"memento-{today:%G-W%V}.png")
    svg_path = png[:-4] + ".svg"
    with open(svg_path, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", "-o", png, svg_path], check=True)
    os.remove(svg_path)

    for old in glob.glob(os.path.join(OUT_DIR, "memento-*.png")):
        if old != png:
            os.remove(old)

    if apply:
        set_wallpaper(png)
    print(png)


def set_wallpaper(png):
    """Set the wallpaper on KDE or GNOME; anywhere else just leave the image."""
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "")
    if "KDE" in desktop:
        subprocess.run(["plasma-apply-wallpaperimage", png], check=True)
    elif "GNOME" in desktop:
        for key in ("picture-uri", "picture-uri-dark"):
            subprocess.run(["gsettings", "set", "org.gnome.desktop.background", key,
                            "file://" + png], check=True)


if __name__ == "__main__":
    main()
