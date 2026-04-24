# Tirzepatide Plasma Concentration Plotter

A standalone, client-side pharmacokinetic (PK) modeling tool for visualizing estimated tirzepatide plasma concentrations over time. Built as a single HTML app — no server, no build step, no dependencies to install.

> ⚠️ **For educational and informational use only.** This tool does not constitute medical advice. Individual pharmacokinetics vary substantially. Never adjust your dosing based on this model without consulting your prescribing physician.

<img width="1251" height="826" alt="tirzplot_ss" src="https://github.com/user-attachments/assets/94849374-1a68-4cc7-af02-c4334b0ca7ce" />

---

## Background

Tirzepatide (brand names Mounjaro, Zepbound) is a dual GIP/GLP-1 receptor agonist administered as a once-weekly subcutaneous injection. Because of its long half-life (~5 days), drug accumulates over several weeks before reaching steady state — making it useful to visualize how plasma concentrations evolve across a titration schedule.

This tool models that behavior using a **one-compartment pharmacokinetic model with first-order absorption and elimination**, parameterized directly from the FDA clinical pharmacology review submitted with NDA 215866 (Eli Lilly, 2022).

---

## Features

- **Injection schedule logging** — add multiple doses with individual dates and amounts
- **Per-injection body weight** — each dose records weight at time of injection; the PK model scales clearance independently per dose based on FDA population PK data
- **Three chart views:**
  - `ng/mL` — plasma concentration in standard clinical units
  - `mg equiv.` — estimated total drug in the central compartment (C × Vd)
  - `Weight` — body weight over time, one point per injection
- **Configurable time range** — 30 days to 1 year
- **Steady state detection** — computed from consecutive pre-dose trough estimates (relative change < 5%), not a fixed heuristic
- **Key statistics** — current estimated concentration, Cmax, Cmin (trough), and steady state status, each with explanatory tooltips
- **Dose markers and TODAY line** overlaid on the PK chart when they fall inside the visible date range
- **Persistent storage** — auto-saves to `localStorage` on every change; status indicator shows whether browser storage is available
- **Export / Import** — download your data as a portable JSON backup; import it on any browser or machine
- **Static hosting friendly** — works without a backend; CDN assets are used for charts, fonts, README rendering, and the donation button

---

## PK Model

Model inputs are sourced from FDA tirzepatide review and labeling documents, with `ka` derived to place the model tmax around 48 hours within the reported 8–72 hour range.

| Parameter | Value | Source |
|---|---|---|
| Elimination half-life (t½) | ~5 days (120 h) | Table 1, NDA 215866 |
| Absorption tmax range (SC) | 8–72 h | FDA labeling |
| Bioavailability (F) | 80.9% | Study GPGE Part D |
| Clearance (CL/F) | 0.061 L/h | Table 1, NDA 215866 |
| Volume of distribution (Vd) | 10.3 L | Table 1, NDA 215866 |
| Plasma protein binding | 99% (albumin) | Section 3.2 |
| Accumulation ratio (QW, AUC0-tau) | ~1.6× by 4 weeks | FDA labeling / review summary |
| Steady state (once-weekly) | ~4 weeks | Table 1, NDA 215866 |
| Dose proportionality | Linear 0.25–15 mg | popPK analysis |

### Equations

Plasma concentration from a single dose is modeled using the **Bateman equation**:

```
C(t) = (F · D / Vd) · (ka / (ka − ke)) · (e^(−ke·t) − e^(−ka·t))
```

Where:
- `D` = dose in mg
- `ka` = absorption rate constant (0.0695 h⁻¹, derived to reproduce tmax ≈ 48 h within the reported 8–72 h range)
- `ke` = elimination rate constant = CL / Vd
- `t` = time since injection in hours

Concentrations from multiple doses are summed by **superposition** (valid given confirmed dose-proportional linear PK across 0.25–15 mg).

### Weight Scaling

Body weight affects tirzepatide exposure via a log-linear power model fit to FDA population PK data:

```
scalar = (weight_kg / 90) ^ (-1.0)
CL_eff = CL / scalar
```

This reflects the FDA-reported finding that a 70 kg patient has ~23% higher AUC, and a 120 kg patient ~21% lower AUC, relative to the 90 kg reference. Because each injection records its own weight, the model correctly handles weight changes across a titration schedule.

### Limitations

- Population-average model only — individual variability is not represented (FDA-reported CV ~22% for Cmax/AUC)
- Single-compartment approximation — tirzepatide PK is more precisely described by a two-compartment model, but the one-compartment fit is adequate for visualization purposes given the available parameters
- Injection site effects (abdomen vs. thigh vs. upper arm) are minor and not separately modeled per FDA findings
- Subcutaneous absorption is modeled as first-order; actual SC absorption can be more complex

---

## Usage

The tool is hosted and ready to use — no installation required. Simply open it in any modern browser.

If you prefer to self-host or run it locally:

1. Clone or download the repository
2. Deploy `index.html`, `README.md`, and `LICENSE` to any static host (Netlify, GitHub Pages, etc.)
3. Or open `index.html` directly from your local filesystem. The core app works as a local file; the README/LICENSE popup depends on the browser allowing local `fetch()` access to the adjacent `README.md` and `LICENSE` files.

Once open:

1. Enter a date, dose amount, and your body weight at the time of injection
2. Click **+ Add Injection**
3. Repeat for each injection in your schedule
4. Use the **ng/mL / mg equiv. / Weight** tabs to switch chart views
5. Use **Export** to download a JSON backup of your data

### Data Persistence

| Browser | localStorage | Notes |
|---|---|---|
| Chrome | ✅ Supported | Recommended |
| Firefox | ✅ Supported | Works normally |
| Edge | ✅ Supported | Works normally |
| Safari | ✅ Supported | Works normally when hosted |
| Private/Incognito | ⚠️ Limited | Storage may be temporary or unavailable; export before closing |

> **Note:** If running from a local `file://` path rather than a hosted URL, Safari may restrict localStorage. Use the **Export** button to save your data in that case.

The storage status indicator in the Injection Schedule panel shows whether auto-save is active. If it shows an amber warning, use the **Export** button to save your data before closing.

### Export / Import Format

Data is stored as a JSON array. Each entry contains:

```json
[
  {
    "dateISO": "2026-04-13T12:00:00.000Z",
    "amount": 2.5,
    "weightKg": 89.8
  }
]
```

This format is intentionally simple and human-readable. You can edit it manually if needed.

---

## Dependencies

No package installation is required. Runtime assets are loaded from CDNs or adjacent static files.

| Library | Version | Purpose |
|---|---|---|
| [Chart.js](https://www.chartjs.org/) | 4.4.1 | Chart rendering |
| [marked.js](https://marked.js.org/) | 9.1.6 | README Markdown rendering |
| [Google Fonts](https://fonts.google.com/) | — | DM Sans, DM Mono typefaces |
| [PayPal Donate SDK](https://www.paypal.com/) | — | Donation button rendering |

The app can be opened without a backend, but it is not fully self-contained offline: charts, fonts, Markdown rendering, the PayPal button, and the README screenshot rely on CDN or remote assets unless they are already cached by the browser.

## Tests

The single HTML file includes a small built-in unit test runner for parsing, serialization, example schedule generation, weight scaling, PK contribution math, concentration summation, and steady-state detection.

Run it from the browser console:

```js
runUnitTests()
```

Or open:

```text
index.html?test=1
```

## Repository Structure

```
tirzplotter/
├── index.html       ← main application
├── README.md
├── LICENSE
└── netlify.toml
```

---

## References

- FDA NDA 215866 Clinical Pharmacology Review — Tirzepatide (Mounjaro), Eli Lilly and Company, 2022. Available at: https://www.accessdata.fda.gov/drugsatfda_docs/nda/2022/215866Orig1s000ClinPharmR.pdf
- FDA Mounjaro prescribing information — current tirzepatide labeling. Available at: https://www.fda.gov/media/191437/download
- DrugBank: Tirzepatide (DB15171) — https://go.drugbank.com/drugs/DB15171

---

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

You are free to share and adapt this work for non-commercial purposes, provided you give appropriate credit and distribute any derivatives under the same license. Commercial use is prohibited. See `LICENSE` for full terms.

---

## Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Eli Lilly and Company or any regulatory authority. It is an independent educational tool. The pharmacokinetic model is a simplification intended for informational visualization only and should not be used for clinical decision-making.
