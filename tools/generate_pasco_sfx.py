"""Generate the original procedural sound effects used by Pasco."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 44_100
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "audio"


def envelope(time: float, duration: float, attack: float = 0.005, power: float = 2.0) -> float:
    if time < 0.0 or time >= duration:
        return 0.0
    if time < attack:
        return time / attack
    return ((duration - time) / max(duration - attack, 0.0001)) ** power


def add_sine_sweep(
    samples: list[float],
    start: float,
    duration: float,
    start_hz: float,
    end_hz: float,
    amplitude: float,
    attack: float = 0.003,
    power: float = 2.2,
) -> None:
    first = int(start * SAMPLE_RATE)
    count = int(duration * SAMPLE_RATE)
    phase = 0.0
    for offset in range(count):
        index = first + offset
        if not 0 <= index < len(samples):
            continue
        time = offset / SAMPLE_RATE
        ratio = time / duration
        frequency = start_hz + (end_hz - start_hz) * ratio
        phase += math.tau * frequency / SAMPLE_RATE
        samples[index] += math.sin(phase) * amplitude * envelope(time, duration, attack, power)


def add_filtered_noise(
    samples: list[float],
    start: float,
    duration: float,
    amplitude: float,
    smoothing: float,
    rng: random.Random,
    attack: float = 0.002,
    power: float = 2.0,
) -> None:
    first = int(start * SAMPLE_RATE)
    count = int(duration * SAMPLE_RATE)
    low_pass = 0.0
    previous_low_pass = 0.0
    for offset in range(count):
        index = first + offset
        if not 0 <= index < len(samples):
            continue
        raw = rng.uniform(-1.0, 1.0)
        low_pass += smoothing * (raw - low_pass)
        band = low_pass - previous_low_pass * 0.72
        previous_low_pass = low_pass
        time = offset / SAMPLE_RATE
        samples[index] += band * amplitude * envelope(time, duration, attack, power)


def add_footstep(samples: list[float], start: float, strength: float, grass: bool, rng: random.Random) -> None:
    if grass:
        add_sine_sweep(samples, start, 0.105, 105.0, 58.0, 0.30 * strength, power=2.8)
        add_filtered_noise(samples, start - 0.012, 0.19, 0.42 * strength, 0.35, rng, power=1.6)
        add_filtered_noise(samples, start + 0.055, 0.11, 0.24 * strength, 0.48, rng, power=2.4)
    else:
        add_sine_sweep(samples, start, 0.12, 135.0, 62.0, 0.48 * strength, power=2.6)
        add_filtered_noise(samples, start, 0.13, 0.42 * strength, 0.16, rng, power=2.0)
        for grain_time, grain_strength in ((0.018, 0.22), (0.046, 0.18), (0.078, 0.13)):
            add_filtered_noise(
                samples,
                start + grain_time,
                0.035,
                grain_strength * strength,
                0.55,
                rng,
                power=3.0,
            )


def make_footstep_loop(grass: bool) -> list[float]:
    duration = 1.0
    samples = [0.0] * int(duration * SAMPLE_RATE)
    rng = random.Random(20260927 if grass else 20260926)
    add_footstep(samples, 0.08, 1.0, grass, rng)
    add_footstep(samples, 0.56, 0.88, grass, rng)
    return samples


def make_head_knockout() -> list[float]:
    duration = 1.25
    samples = [0.0] * int(duration * SAMPLE_RATE)
    rng = random.Random(1492)

    # Stone contact: a sharp crack followed by a hollow cartoon-like bonk.
    add_filtered_noise(samples, 0.015, 0.075, 0.78, 0.55, rng, attack=0.001, power=3.8)
    add_sine_sweep(samples, 0.02, 0.22, 510.0, 205.0, 0.62, power=2.8)
    add_sine_sweep(samples, 0.025, 0.16, 940.0, 420.0, 0.25, power=3.0)
    add_sine_sweep(samples, 0.03, 0.20, 122.0, 66.0, 0.52, power=2.3)

    # Brief descending ring communicates dizziness and loss of balance.
    add_sine_sweep(samples, 0.20, 0.48, 760.0, 285.0, 0.18, attack=0.018, power=1.7)
    add_sine_sweep(samples, 0.25, 0.38, 1140.0, 440.0, 0.09, attack=0.02, power=1.8)

    # A low body thump and dust burst complete the fall.
    add_sine_sweep(samples, 0.68, 0.30, 92.0, 43.0, 0.62, attack=0.006, power=2.4)
    add_filtered_noise(samples, 0.69, 0.25, 0.36, 0.12, rng, attack=0.004, power=2.3)
    add_filtered_noise(samples, 0.82, 0.24, 0.12, 0.32, rng, attack=0.01, power=1.8)
    return samples


def write_wav(name: str, samples: list[float], peak: float = 0.88) -> None:
    maximum = max(abs(value) for value in samples) or 1.0
    scale = peak / maximum
    pcm = bytearray()
    for value in samples:
        clamped = max(-1.0, min(1.0, value * scale))
        pcm.extend(struct.pack("<h", int(clamped * 32_767)))

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT_DIR / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)


def main() -> None:
    write_wav("pasco footsteps dirt.wav", make_footstep_loop(grass=False), peak=0.76)
    write_wav("pasco footsteps grass.wav", make_footstep_loop(grass=True), peak=0.68)
    write_wav("stone head knockout.wav", make_head_knockout(), peak=0.86)


if __name__ == "__main__":
    main()
