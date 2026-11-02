"""Render the charts, the lineage diagram and the stats block for the README.

Everything is read from the warehouse that `dbt build` just produced, so the
numbers in the README are always the numbers from a real run.
"""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

import duckdb
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
IMG = ROOT / "docs" / "images"
IMG.mkdir(parents=True, exist_ok=True)
DB = ROOT / "data" / "warehouse" / "saas.duckdb"

NAVY, TEAL, GREY, RULE = "#1F3552", "#0F6B63", "#5A6672", "#C9D2DA"
SAND, LIGHT = "#F3EEE3", "#EDF1F5"

plt.rcParams.update({"font.size": 9})


def style(ax):
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color(RULE)
    ax.tick_params(colors=GREY, labelsize=8.5)
    ax.yaxis.grid(True, color="#E6EAEE", linewidth=0.7)
    ax.set_axisbelow(True)


def mrr_trend(con):
    df = con.sql("select month_start, mrr_usd, net_new_mrr_usd from marts.mart_mrr_summary order by 1").df()
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(9, 5.4), dpi=200, sharex=True,
                                  gridspec_kw={"height_ratios": [2.4, 1]})
    style(ax)
    ax.plot(df["month_start"], df["mrr_usd"] / 1000, color=TEAL, linewidth=2.2, marker="o", markersize=3)
    ax.fill_between(df["month_start"], df["mrr_usd"] / 1000, color=TEAL, alpha=0.10)
    ax.set_title("MRR by month (USD thousands)", color=NAVY, fontsize=11.5, loc="left",
                 pad=10, fontweight="bold")
    ax.set_ylabel("USD '000", color=GREY, fontsize=8.5)

    style(ax2)
    colours = ["#0F6B63" if v >= 0 else "#B4483C" for v in df["net_new_mrr_usd"]]
    ax2.bar(df["month_start"], df["net_new_mrr_usd"] / 1000, color=colours, width=18)
    ax2.axhline(0, color=RULE, linewidth=0.8)
    ax2.set_title("Net new MRR", color=NAVY, fontsize=10, loc="left", pad=6, fontweight="bold")
    ax2.set_ylabel("USD '000", color=GREY, fontsize=8.5)
    ax2.yaxis.grid(True, color="#E6EAEE", linewidth=0.7)
    fig.autofmt_xdate(rotation=45, ha="right")
    fig.tight_layout()
    fig.savefig(IMG / "mrr_trend.png", facecolor="white")
    plt.close(fig)


def retention_heatmap(con):
    df = con.sql("""
        select cohort_month, months_since_start, retention_pct
        from marts.mart_churn_cohorts
        where cohort_month >= date '2025-01-01'
    """).df()
    pivot = df.pivot(index="cohort_month", columns="months_since_start", values="retention_pct")
    fig, ax = plt.subplots(figsize=(9, 5.2), dpi=200)
    im = ax.imshow(pivot.values, cmap="BuGn", vmin=0, vmax=100, aspect="auto")
    ax.set_xticks(range(len(pivot.columns)), [f"M{c}" for c in pivot.columns], fontsize=8)
    ax.set_yticks(range(len(pivot.index)), [str(i)[:7] for i in pivot.index], fontsize=8)
    for i in range(pivot.shape[0]):
        for j in range(pivot.shape[1]):
            value = pivot.values[i, j]
            if value == value:
                ax.text(j, i, f"{value:.0f}", ha="center", va="center", fontsize=6.8,
                        color="white" if value > 55 else "#1F3552")
    ax.set_title("Cohort retention: % of the signup cohort still paying",
                 color=NAVY, fontsize=11.5, loc="left", pad=10, fontweight="bold")
    ax.set_xlabel("Months since first subscription", color=GREY, fontsize=8.5)
    ax.set_ylabel("Signup cohort", color=GREY, fontsize=8.5)
    for s in ax.spines.values():
        s.set_visible(False)
    fig.colorbar(im, ax=ax, shrink=0.7, label="retention %")
    fig.tight_layout()
    fig.savefig(IMG / "retention_heatmap.png", facecolor="white")
    plt.close(fig)


def plan_mix(con):
    df = con.sql("select plan_name, mrr_usd, accounts from marts.mart_revenue_by_plan order by mrr_usd").df()
    fig, ax = plt.subplots(figsize=(9, 3.2), dpi=200)
    style(ax)
    ax.barh(df["plan_name"], df["mrr_usd"] / 1000, color=NAVY, height=0.55)
    for y, (value, accounts) in enumerate(zip(df["mrr_usd"] / 1000, df["accounts"])):
        ax.text(value + df["mrr_usd"].max() / 1000 * 0.01, y,
                f"${value:,.1f}k   {accounts} accounts", va="center", fontsize=8.4, color=GREY)
    ax.set_xlim(0, df["mrr_usd"].max() / 1000 * 1.35)
    ax.set_title("Current-month MRR by plan tier", color=NAVY, fontsize=11.5, loc="left",
                 pad=10, fontweight="bold")
    ax.xaxis.grid(True, color="#E6EAEE", linewidth=0.7)
    ax.yaxis.grid(False)
    fig.tight_layout()
    fig.savefig(IMG / "plan_mix.png", facecolor="white")
    plt.close(fig)


def lineage():
    manifest = json.loads((ROOT / "target" / "manifest.json").read_text())
    nodes = manifest["nodes"]
    parents = manifest["parent_map"]

    layers = {"source": [], "staging": [], "intermediate": [], "marts": []}
    for uid, node in nodes.items():
        if node["resource_type"] != "model":
            continue
        path = node["original_file_path"]
        if "staging/" in path:
            layers["staging"].append((uid, node["name"]))
        elif "intermediate/" in path:
            layers["intermediate"].append((uid, node["name"]))
        else:
            layers["marts"].append((uid, node["name"]))
    # sources live under manifest["sources"], not manifest["nodes"]
    for uid, node in manifest.get("sources", {}).items():
        layers["source"].append((uid, node["name"]))

    for key in layers:
        layers[key].sort(key=lambda x: x[1])

    fig, ax = plt.subplots(figsize=(11.5, 5.4), dpi=200)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")
    ax.text(1, 96, "dbt lineage - sources to marts", fontsize=13, fontweight="bold",
            color=NAVY, va="top")
    ax.text(1, 91.5, f"{sum(len(v) for v in layers.values())} nodes, "
                     f"{len(manifest['nodes'])} manifest entries",
            fontsize=8.5, color=GREY, va="top")

    xs = {"source": 4, "staging": 28, "intermediate": 53, "marts": 77}
    faces = {"source": SAND, "staging": LIGHT, "intermediate": LIGHT, "marts": NAVY}
    texts = {"source": NAVY, "staging": NAVY, "intermediate": NAVY, "marts": "white"}
    pos = {}
    for layer, items in layers.items():
        n = max(len(items), 1)
        for i, (uid, name) in enumerate(items):
            y = 84 - (i + 1) * (78 / (n + 0.6))
            pos[uid] = (xs[layer], y)
            ax.add_patch(FancyBboxPatch((xs[layer], y), 17, 4.6,
                                        boxstyle="round,pad=0.3,rounding_size=0.8",
                                        linewidth=0, facecolor=faces[layer], zorder=2))
            ax.text(xs[layer] + 8.5, y + 2.3, name, ha="center", va="center",
                    fontsize=7.4, color=texts[layer], zorder=3,
                    fontweight="bold" if layer == "marts" else "normal")

    for child, parents_list in parents.items():
        if child not in pos:
            continue
        for parent in parents_list:
            if parent not in pos:
                continue
            x1, y1 = pos[parent]
            x2, y2 = pos[child]
            if x2 <= x1:
                continue
            ax.add_patch(FancyArrowPatch((x1 + 17, y1 + 2.3), (x2, y2 + 2.3),
                                         arrowstyle="-|>", mutation_scale=7,
                                         linewidth=0.8, color="#B9C3CD", zorder=1,
                                         connectionstyle="arc3,rad=0.06", shrinkA=1, shrinkB=1))
    fig.tight_layout(pad=0.3)
    fig.savefig(IMG / "lineage.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)


def stats(con) -> dict:
    q = lambda s: con.execute(s).fetchone()[0]  # noqa: E731
    latest = q("select max(month_start) from marts.mart_mrr_summary")
    out = {
        "accounts": int(q("select count(*) from marts.dim_accounts")),
        "subscriptions": int(q("select count(*) from staging.stg_subscriptions")),
        "invoices": int(q("select count(*) from marts.fct_invoices")),
        "mrr_rows": int(q("select count(*) from marts.fct_mrr_monthly")),
        "months": int(q("select count(*) from marts.mart_mrr_summary")),
        "latest_month": str(latest),
        "mrr_usd": float(q("select mrr_usd from marts.mart_mrr_summary order by month_start desc limit 1")),
        "arr_usd": float(q("select arr_usd from marts.mart_mrr_summary order by month_start desc limit 1")),
        "paying_accounts": int(q("select paying_accounts from marts.mart_mrr_summary order by month_start desc limit 1")),
        "growth_first_to_last": float(q(
            "select round(100.0 * (max(mrr_usd) / min(mrr_usd) - 1), 1) from marts.mart_mrr_summary")),
        "churn_months": int(q("select count(*) from marts.mart_mrr_summary where churned_mrr_usd > 0")),
        "retention_m6": float(q("select round(avg(retention_pct), 1) from marts.mart_churn_cohorts where months_since_start = 6")),
        "tests": len(json.loads((ROOT / "target" / "run_results.json").read_text())["results"]),
    }
    (ROOT / "reports").mkdir(exist_ok=True)
    (ROOT / "reports" / "stats.json").write_text(json.dumps(out, indent=2))
    return out


if __name__ == "__main__":
    con = duckdb.connect(str(DB), read_only=True)
    mrr_trend(con)
    retention_heatmap(con)
    plan_mix(con)
    lineage()
    print(json.dumps(stats(con), indent=2))
    con.close()
