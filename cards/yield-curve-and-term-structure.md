---
created: 2026-06-07
last_verified: 2026-08-02
tags: [finance, economics, study]
title: Yield Curve & Interest Rate Term Structure
---

# Yield Curve & Interest Rate Term Structure

_收益率曲线与利率期限结构_

**Created:** 2026-06-07 | **Source:** Self-study (Kagura finance [[study-workflow|study]] #1)

## What Is a Yield Curve?

A **yield curve** plots the interest rates (yields) of bonds with equal credit quality but differing maturities — typically U.S. Treasury bonds. The x-axis is time to maturity (1mo → 30yr), the y-axis is yield (%).

It answers: **How much more do investors demand to lock up money for longer?**

## Three Classic Shapes

### 1. Normal (Upward-Sloping) 📈
- Short-term yields < Long-term yields
- **Interpretation:** Economy is healthy; investors expect growth and possibly higher future inflation
- **Why it's "normal":** Lenders demand more compensation for longer lock-up (term premium)
- **Typical spread:** 10Y − 2Y ≈ +100–200 bps

### 2. Inverted (Downward-Sloping) 📉
- Short-term yields > Long-term yields
- **Interpretation:** Markets expect economic slowdown/recession; flight to safety drives long-term bond prices up (yields down)
- **Historical signal:** 10Y−2Y inversion has preceded every U.S. recession since 1955, with only one false positive (1966)
- **Lead time:** Typically 6–24 months before recession onset

### 3. Flat
- Similar yields across maturities
- **Interpretation:** Transition state — economy shifting between expansion and contraction
- Often seen during Fed rate hike cycles nearing their peak

### Bonus: Humped / Bear Steepener / Bull Flattener
- **Humped:** Medium-term yields highest (rare, usually transient)
- **Bear Steepener:** Long-term rates rise faster than short-term (growth expectations up)
- **Bull Flattener:** Short-term rates rise while long-term stay flat/fall (Fed tightening, recession fears)

## Key Theories Explaining the Shape

### 1. Expectations Theory (期望理论)
- Long-term rates = average of expected future short-term rates
- If markets expect rate cuts → curve inverts
- **Weakness:** Ignores risk premium; doesn't explain why curve is usually upward-sloping

### 2. Liquidity Preference Theory (流动性偏好理论)
- Investors prefer shorter maturities (more liquid)
- Long-term bonds must offer a **term premium** to compensate
- Explains the normal upward slope as default state

### 3. Market Segmentation Theory (市场分割理论)
- Different investors operate in different maturity segments (banks buy short, pensions buy long)
- Supply/demand in each segment determines that segment's yield independently
- **Preferred Habitat Theory** (改良版): Investors have preferred maturities but will move for sufficient premium

## Practical Metrics

| Metric | Formula | What It Tells You |
|--------|---------|-------------------|
| **2s10s Spread** | 10Y yield − 2Y yield | Most-watched recession indicator |
| **3m10y Spread** | 10Y yield − 3M yield | Fed's preferred recession predictor (slightly better track record) |
| **Term Premium** | Long yield − expected path of short rates | Compensation for duration risk |
| **Real Yield** | Nominal yield − inflation expectations | True purchasing-power return |

## Why It Matters

### For Macro Analysis
- **Steepening after inversion** → recession is imminent (the "un-inversion" is the danger signal, not the inversion itself)
- Curve shape directly reflects market's consensus on Fed policy path and growth outlook

### For Banks
- Banks borrow short (deposits) and lend long (mortgages)
- Normal curve = profitable spread; Inverted curve = margin squeeze → tighter lending → self-fulfilling slowdown

### For Bond Investors
- **Roll-down return:** In a normal curve, a bond "rolls down" to lower yields as it ages → capital gain
- **Duration risk:** Steeper curve = more duration risk for long bonds
- **Barbell vs Bullet:** Strategies to position along the curve

### For Equity Investors
- Inverted curve historically = reduce risk exposure over next 12-18 months
- Steepening from inversion = early recovery signal (but recession often hasn't hit yet)

## The 2022-2024 Inversion Episode

- **July 2022:** 2s10s inverted (10Y < 2Y) — longest inversion in modern history
- **Deepest point:** ~-108 bps (July 2023)
- **Un-inverted:** September 2024
- **Debate:** "This time is different" vs "recession is just delayed"
- Key lesson: **Duration of inversion matters as much as depth**

## Mental Model 🧠

> Think of the yield curve as the market's **collective weather forecast** for the economy:
> - Normal = clear skies ahead
> - Flat = clouds gathering
> - Inverted = storm warning
> - Un-inverting rapidly = the storm is arriving

## Related Concepts to Study Next
- [ ] Duration & Convexity (债券久期与凸性)
- [ ] Fed Funds Rate & Monetary Policy Transmission
- [ ] Credit Spreads (信用利差)
- [ ] TIPS & Breakeven Inflation Rate
- [ ] Carry Trade (套息交易)

---

_First finance study card. Building from macro fundamentals → fixed income → derivatives → portfolio theory. Part of [[study-workflow]] and [[knowledge-is-a-graph]]._
