#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "matplotlib>=3.8.0",
#     "numpy>=1.26.0",
#     "seaborn>=0.13.0",
# ]
# ///

import matplotlib.pyplot as plt  # ty:ignore[unresolved-import]

plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["EB Garamond"]
plt.rcParams["font.size"] = 16

fig, ax = plt.subplots(figsize=(8, 5.5))

data_laptop = {
    "Naïve": 1.14 * 10**9,
    "CVTTPS2DQ": 5.05 * 10**9,
}

data_desktop = {
    "Naïve": 2.59 * 10**9,
    "CVTTPS2DQ": 20.57 * 10**9,
}

COLOURS = ["#5b69e4", "#f33b73"]

# ax.bar(
#     ["Naïve", "CVTTPS2DQ"],
#     [1.14 * 10**9, 5.05 * 10**9],
#     width=0.5,
#     facecolor=COLOURS,
# )

for i, (label, value) in enumerate(data_laptop.items()):
    ax.bar(
        i - 0.2,
        value,
        width=0.375,
        facecolor=COLOURS[0],
        label="Intel® Core™ i7-13850HX" if i == 0 else None,
    )

for i, (label, value) in enumerate(data_desktop.items()):
    ax.bar(
        i + 0.2,
        value,
        width=0.375,
        facecolor=COLOURS[1],
        label="AMD Ryzen™ 9 9950X" if i == 0 else None,
    )

ax.legend(loc="upper left", fontsize=12)

ax.set_xticks([0, 1])
ax.set_xticklabels(["Naïve", "SIMD"])

ax.set_title("Speedup from enabling Autovectorisation", fontsize=20, pad=8)

ax.set_ylabel("Floating-point values processed per second")

ax.set_facecolor("#fafafa")
fig.patch.set_facecolor("#fafafa")

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.spines["bottom"].set_linewidth(1.5)
ax.spines["left"].set_linewidth(1.5)

plt.savefig("cvttps2dq-speedup.svg", dpi=200, bbox_inches="tight")
