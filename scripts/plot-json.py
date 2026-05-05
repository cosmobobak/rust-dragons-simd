#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "matplotlib>=3.8.0",
#     "numpy>=1.26.0",
#     "seaborn>=0.13.0",
# ]
# ///

import matplotlib.pyplot as plt

plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["EB Garamond"]
plt.rcParams["font.size"] = 16

fig, ax = plt.subplots(figsize=(8, 5.5))

COLOURS = ["#5b69e4", "#f33b73"]

# data_laptop = {
#     "Naïve": 1.14 * 10**9,
#     "SIMD": 5.05 * 10**9,
# }

data_desktop = {
    "Naïve": 2.86 * 10**9,
    "SIMD": 87.35 * 10**9,
}

# ax.bar(
#     ["Naïve", "CVTTPS2DQ"],
#     [1.14 * 10**9, 5.05 * 10**9],
#     width=0.5,
#     facecolor=COLOURS,
# )

# for i, (label, value) in enumerate(data_laptop.items()):
#     ax.bar(
#         i - 0.2,
#         value,
#         width=0.375,
#         facecolor=COLOURS[0],
#         label="Laptop" if i == 0 else None,
#     )

for i, (label, value) in enumerate(data_desktop.items()):
    ax.bar(
        i,  # + 0.2,
        value,
        width=0.375 * 2,
        # facecolor=COLOURS[1],
        facecolor=COLOURS[i],
        label="Desktop" if i == 0 else None,
    )

# ax.legend(loc="upper left", fontsize=12)

ax.set_xticks([0, 1])
ax.set_xticklabels(["Naïve", "SIMD"])

ax.set_title("Speedup from SIMD implementation", fontsize=20, pad=8)

ax.set_ylabel("GBs of JSON processed per second")

ax.set_facecolor("#fafafa")
fig.patch.set_facecolor("#fafafa")

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.spines["bottom"].set_linewidth(1.5)
ax.spines["left"].set_linewidth(1.5)

plt.savefig("json-speedup.svg", dpi=200, bbox_inches="tight")
