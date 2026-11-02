"""Generate the raw SaaS billing extracts into data/raw/.

Deliberately messy, because the staging models exist to clean it: two date
formats, amounts with thousands separators, duplicate invoices from a re-run
billing job, inconsistent plan-name casing, and a handful of negative
"credit" invoices that are not real revenue.
"""

from __future__ import annotations

import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"
SEED_DIR.mkdir(parents=True, exist_ok=True)

PLANS = [
    ("PLAN-STARTER", "Starter", 2900, "monthly"),
    ("PLAN-GROWTH", "Growth", 9900, "monthly"),
    ("PLAN-SCALE", "Scale", 24900, "monthly"),
    ("PLAN-ENTERPRISE", "Enterprise", 74900, "monthly"),
]
INDUSTRIES = ["SaaS", "Fintech", "Retail", "Healthcare", "Logistics", "Education"]
COUNTRIES = ["India", "India", "India", "United States", "United Kingdom", "Singapore", "UAE"]
METHODS = ["card", "upi", "bank_transfer", "card", "card"]

START = date(2024, 11, 1)
END = date(2026, 10, 31)


def parse(value: str) -> date:
    """Read either of the two date formats the exports use."""
    value = value.strip()
    for fmt in ("%Y-%m-%d", "%d/%m/%Y"):
        try:
            return datetime.strptime(value, fmt).date()
        except ValueError:
            continue
    raise ValueError(f"unparseable date: {value!r}")


def messy_date(d: date, rng: random.Random) -> str:
    return d.strftime("%d/%m/%Y") if rng.random() < 0.15 else d.isoformat()


def money(cents: int, rng: random.Random) -> str:
    value = f"{cents / 100:.2f}"
    if cents >= 100000 and rng.random() < 0.2:
        return value.replace(".", ",", 0).replace(",", ".", 0)  # 1.234,56 style
    return value


def main(seed: int = 7) -> None:
    rng = random.Random(seed)

    # ------------------------------------------------------------- plans
    with (SEED_DIR / "plans.csv").open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["plan_id", "plan_name", "monthly_price_cents", "billing_interval"])
        for pid, name, cents, interval in PLANS:
            w.writerow([pid, name.upper() if rng.random() < 0.3 else name, cents, interval])

    # ---------------------------------------------------------- accounts
    accounts = []
    for i in range(1, 181):
        created = START + timedelta(days=rng.randint(0, 600))
        accounts.append({
            "account_id": f"ACC-{i:04d}",
            "account_name": f"{rng.choice(['Nova', 'Vertex', 'Lumen', 'Orbit', 'Kite', 'Arbor'])} "
                            f"{rng.choice(INDUSTRIES)} {i}",
            "country": rng.choice(COUNTRIES),
            "industry": rng.choice(INDUSTRIES),
            "segment": rng.choice(["smb", "smb", "mid", "enterprise"]),
            "created_at": messy_date(created, rng),
        })
    with (SEED_DIR / "accounts.csv").open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(accounts[0]))
        w.writeheader()
        w.writerows(accounts)

    # ----------------------------------------------------- subscriptions
    subs, sid = [], 1
    for acc in accounts:
        start = parse(acc["created_at"])
        if start < START:
            start = START + timedelta(days=rng.randint(0, 20))
        plan = rng.choices(PLANS, weights=[5, 4, 2, 1])[0]
        seats = {"PLAN-STARTER": 1, "PLAN-GROWTH": 3, "PLAN-SCALE": 8, "PLAN-ENTERPRISE": 20}[plan[0]]
        seats = max(1, seats + rng.randint(-1, 3))

        ended = None
        status = "active"
        if rng.random() < 0.35:
            end = start + timedelta(days=rng.randint(60, 600))
            if end < END:
                ended, status = end, "churned"
        subs.append({
            "subscription_id": f"SUB-{sid:05d}",
            "account_id": acc["account_id"],
            "plan_id": plan[0],
            "started_at": messy_date(start, rng),
            "ended_at": "" if ended is None else messy_date(ended, rng),
            "status": status,
            "seats": seats,
        })
        sid += 1

        # some accounts upgrade once, on a month boundary: plan changes take
        # effect at the next billing cycle, so no month is ever billed twice
        if ended is None and rng.random() < 0.25:
            upgrade = rng.choice(PLANS[1:])
            switch = (start.replace(day=1) + timedelta(days=rng.randint(60, 400))).replace(day=1)
            if switch <= END:
                subs[-1]["ended_at"] = messy_date(switch - timedelta(days=1), rng)
                subs[-1]["status"] = "upgraded"
                subs.append({
                    "subscription_id": f"SUB-{sid:05d}",
                    "account_id": acc["account_id"],
                    "plan_id": upgrade[0],
                    "started_at": messy_date(switch, rng),
                    "ended_at": "",
                    "status": "active",
                    "seats": seats + 2,
                })
                sid += 1

    with (SEED_DIR / "subscriptions.csv").open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(subs[0]))
        w.writeheader()
        w.writerows(subs)

    # ---------------------------------------------------------- invoices
    plan_by_id = {p[0]: p for p in PLANS}
    invoices, payments, iid, pid = [], [], 1, 1
    for sub in subs:
        price = plan_by_id[sub["plan_id"]][2] * int(sub["seats"])
        start = parse(sub["started_at"])
        end = END
        if sub["ended_at"]:
            end = parse(sub["ended_at"])

        month = start.replace(day=1)
        while month <= end:
            amount = price
            status = rng.choices(["paid", "open", "void"], weights=[92, 6, 2])[0]
            if status == "void":
                amount = -amount  # credit note, not revenue
            invoice_date = month
            invoices.append({
                "invoice_id": f"INV-{iid:06d}",
                "account_id": sub["account_id"],
                "subscription_id": sub["subscription_id"],
                "invoice_date": messy_date(invoice_date, rng),
                "amount_cents": money(amount, rng),
                "currency": "USD",
                "status": status,
            })
            if status == "paid":
                paid_at = invoice_date + timedelta(days=rng.randint(0, 25))
                payments.append({
                    "payment_id": f"PAY-{pid:06d}",
                    "invoice_id": f"INV-{iid:06d}",
                    "paid_at": messy_date(paid_at, rng),
                    "amount_cents": money(amount, rng),
                    "method": rng.choice(METHODS),
                })
                pid += 1
            iid += 1
            month = (month.replace(day=28) + timedelta(days=7)).replace(day=1)

    # duplicate invoices from a re-run billing job
    for _ in range(40):
        invoices.append(dict(rng.choice(invoices)))

    with (SEED_DIR / "invoices.csv").open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(invoices[0]))
        w.writeheader()
        w.writerows(invoices)

    with (SEED_DIR / "payments.csv").open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(payments[0]))
        w.writeheader()
        w.writerows(payments)

    print(f"plans {len(PLANS)} | accounts {len(accounts)} | subscriptions {len(subs)} | "
          f"invoices {len(invoices)} | payments {len(payments)}")


if __name__ == "__main__":
    main()
