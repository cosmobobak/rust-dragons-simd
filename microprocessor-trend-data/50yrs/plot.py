#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.14"
# dependencies = [
#     "matplotlib>=3.8.0",
#     "numpy>=1.26.0",
#     "seaborn>=0.13.0",
# ]
# ///

from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np

plt.rcParams["font.family"] = "serif"
plt.rcParams["font.serif"] = ["EB Garamond"]


def read_dat(filename):
    """Read a gnuplot-style .dat file, skipping comments (#) and #### separators."""
    years, values = [], []
    path = Path(filename)
    if not path.exists():
        print(f"Warning: {filename} not found, skipping.")
        return np.array([]), np.array([])
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            if len(parts) >= 2:
                try:
                    years.append(float(parts[0]))
                    values.append(float(parts[1]))
                except ValueError:
                    continue
    return np.array(years), np.array(values)


# --- style config matching gnuplot script ---
series = [
    (
        "cores.dat",
        "o",
        "#000000",
        "d",  # diamond
        [("Number of", 2023, 2e1), ("Logical Cores", 2023, 6.6e0)],
    ),
    (
        "frequency.dat",
        "s",
        "#008800",
        "s",  # square
        [("Frequency (MHz)", 2023, 3e3)],
    ),
    (
        "specint.dat",
        "o",
        "#0000BB",
        "o",  # circle
        [
            ("Single-Thread", 2023, 1.5e5),
            ("Performance", 2023, 5e4),
            (r"(SpecINT ×10³)", 2023, 1.9e4),
        ],
    ),
    (
        "transistors.dat",
        "^",
        "#CC6600",
        "^",  # triangle up
        [("Transistors", 2023, 6e6), ("(thousands)", 2023, 2e6)],
    ),
    (
        "watts.dat",
        "v",
        "#BB0000",
        "v",  # inverted triangle
        [("Typical Power", 2023, 3e2), ("(Watts)", 2023, 1e2)],
    ),
]

# gnuplot pt mapping: 13→diamond, 5→square, 7→circle, 9→tri_up, 11→tri_down
marker_map = {
    "cores.dat": "D",
    "frequency.dat": "s",
    "specint.dat": "o",
    "transistors.dat": "^",
    "watts.dat": "v",
}

fig, ax = plt.subplots(figsize=(16, 5.5))

for filename, _m, color, _m2, labels in series:
    marker = marker_map[filename]
    x, y = read_dat(filename)
    if len(x) > 0:
        ax.scatter(
            x,
            y,
            marker=marker,
            c=color,
            s=30,
            edgecolors=color,
            linewidths=0.8,
            zorder=3,
        )
    # right-side labels
    for text, lx, ly in labels:
        ax.text(lx, ly, text, color=color, fontsize=16, va="center", clip_on=False)

# --- axes ---CCC
ax.set_yscale("log")
ax.set_xlim(1970, 2022.5)
ax.set_ylim(0.2, 7e7)
# ax.set_xlabel("Year")
ax.yaxis.set_major_formatter(
    ticker.FuncFormatter(
        lambda val, pos: r"$10^{%d}$" % int(np.log10(val)) if val > 0 else ""
    )
)
ax.yaxis.set_minor_locator(ticker.NullLocator())
ax.grid(True, which="major", ls="-", lw=0.5, alpha=0.5)

# extra right margin for labels
fig.subplots_adjust(right=0.64)

ax.set_title("50 Years of Microprocessor Trend Data", fontsize=20)

ax.set_facecolor("#fafafa")
fig.patch.set_facecolor("#fafafa")

# attribution
# (placed in slide manually rather than on image, looks nicer)
# ax.text(
#     1970,
#     6e-3,
#     "Original data up to the year 2010 collected and plotted by "
#     "M. Horowitz, F. Labonte, O. Shacham, K. Olukotun, L. Hammond, "
#     "and C. Batten",
#     fontsize=6,
#     color="#000000",
#     va="center",
#     clip_on=False,
# )
# ax.text(
#     1970,
#     3e-3,
#     "New plot and data collected for 2010-2021 by K. Rupp",
#     fontsize=6,
#     color="#000000",
#     va="center",
#     clip_on=False,
# )

ax.spines["top"].set_linewidth(1.5)
ax.spines["right"].set_linewidth(1.5)
ax.spines["bottom"].set_linewidth(1.5)
ax.spines["left"].set_linewidth(1.5)

plt.savefig("50-years-processor-trend.png", dpi=200, bbox_inches="tight")
plt.savefig("50-years-processor-trend.eps", bbox_inches="tight")
print("Saved 50-years-processor-trend.png and .eps")
