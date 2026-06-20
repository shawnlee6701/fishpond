#!/usr/bin/env python3
"""Remove baked gray/white checkerboards from supplied illustration PNGs."""

from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSETS = [
    "Design/Catch Fish King/screen.png",
    "Design/Earn More/screen.png",
    "Design/Earn Less/screen.png",
    "Design/Win More/screen.png",
    "Design/Win Less/screen.png",
    "Design/Bankrupt/screen.png",
]


def is_checker_pixel(pixel: tuple[int, int, int]) -> bool:
    red, green, blue = pixel
    return min(pixel) >= 214 and max(pixel) - min(pixel) <= 18


def clean(source: Path) -> Path:
    image = Image.open(source).convert("RGB")
    width, height = image.size
    pixels = image.load()
    background = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if background[index] or not is_checker_pixel(pixels[x, y]):
            return
        background[index] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    alpha = Image.new("L", image.size, 255)
    alpha_pixels = alpha.load()
    for y in range(height):
        row = y * width
        for x in range(width):
            if background[row + x]:
                alpha_pixels[x, y] = 0

    # Pull the matte one pixel into the artwork, then feather it slightly. This
    # removes the pale checkerboard fringe without softening the ink drawing.
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.45))
    output = image.convert("RGBA")
    output.putalpha(alpha)
    destination = source.with_name("screen_clean.png")
    output.save(destination, optimize=True)
    return destination


def main() -> None:
    for relative_path in ASSETS:
        destination = clean(ROOT / relative_path)
        print(destination.relative_to(ROOT))


if __name__ == "__main__":
    main()
