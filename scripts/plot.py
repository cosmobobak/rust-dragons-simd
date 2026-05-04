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

fig, ax = plt.subplots(figsize=(8, 5.5))

ax.bar(
    ["Naïve", "CVTTPS2DQ"], [1.14, 5.05], width=0.5, facecolor=["#5b69e4", "#f33b73"]
)

ax.set_title("Speedup from enabling Autovectorisation", fontsize=20, pad=8)

ax.set_facecolor("#fafafa")
fig.patch.set_facecolor("#fafafa")

ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
ax.spines["bottom"].set_linewidth(1.5)
ax.spines["left"].set_linewidth(1.5)

plt.savefig("cvttps2dq-speedup.svg", dpi=200, bbox_inches="tight")
