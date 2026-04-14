# Tirzepatide Plasma Concentration Plotter

A standalone, client-side pharmacokinetic (PK) modeling tool for visualizing estimated tirzepatide plasma concentrations over time. Built as a single HTML file — no server, no build step, no dependencies to install.

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
- **Steady state detection** — computed from the simulated curve (trough-to-trough variance < 5%), not a fixed heuristic
- **Key statistics** — current estimated concentration, Cmax, Cmin (trough), and steady state status, each with explanatory tooltips
- **Dose markers and TODAY line** overlaid on the chart
- **Persistent storage** — auto-saves to `localStorage` on every change; status indicator shows whether browser storage is available
- **Export / Import** — download your data as a portable JSON backup; import it on any browser or machine
- **Fully offline** after initial load (requires internet only for Google Fonts and Chart.js CDN on first open)

---

## PK Model

All parameters are sourced from the FDA NDA 215866 Clinical Pharmacology Review (Eli Lilly, 2022).

| Parameter | Value | Source |
|---|---|---|
| Elimination half-life (t½) | ~5 days (120 h) | Table 1, NDA 215866 |
| Absorption tmax range (SC) | 24–72 h | Tables 3–4, NDA 215866 |
| Bioavailability (F) | 80.9% | Study GPGE Part D |
| Clearance (CL/F) | 0.061 L/h | Table 1, NDA 215866 |
| Volume of distribution (Vd) | 10.3 L | Table 1, NDA 215866 |
| Plasma protein binding | 99% (albumin) | Section 3.2 |
| Accumulation ratio (QW) | ~1.7× | Section 3.2 |
| Steady state (once-weekly) | ~4 weeks | Table 1, NDA 215866 |
| Dose proportionality | Linear 0.25–15 mg | popPK analysis |

### Equations

Plasma concentration from a single dose is modeled using the **Bateman equation**:

```
C(t) = (F · D / Vd) · (ka / (ka − ke)) · (e^(−ke·t) − e^(−ka·t))
```

Where:
- `D` = dose in mg
- `ka` = absorption rate constant (0.0695 h⁻¹, derived to reproduce tmax ≈ 48 h)
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

1. Download `tirzepatide_pk_plotter.html`
2. Open it in any modern browser (Chrome recommended; see Storage Notes below)
3. Enter a date, dose amount, and your body weight at the time of injection
4. Click **+ Add Injection**
5. Repeat for each injection in your schedule
6. Use the **ng/mL / mg equiv. / Weight** tabs to switch chart views
7. Use **Export** to download a JSON backup of your data

### Data Persistence

| Browser | localStorage | Notes |
|---|---|---|
| Chrome | ✅ Supported | Recommended |
| Firefox | ✅ Supported | Works normally |
| Edge | ✅ Supported | Works normally |
| Safari (file://) | ⚠️ Restricted | Use Export/Import instead |
| Private/Incognito | ⚠️ Session only | Data lost on close; export before closing |

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

All loaded from CDN — no local installation required.

| Library | Version | Purpose |
|---|---|---|
| [Chart.js](https://www.chartjs.org/) | 4.4.1 | Chart rendering |
| [Google Fonts](https://fonts.google.com/) | — | DM Sans, DM Mono typefaces |

The tool will function without internet access if both resources are already cached by the browser.

---

## References

- FDA NDA 215866 Clinical Pharmacology Review — Tirzepatide (Mounjaro), Eli Lilly and Company, 2022. Available at: https://www.accessdata.fda.gov/drugsatfda_docs/nda/2022/215866Orig1s000ClinPharmR.pdf
- DrugBank: Tirzepatide (DB15171) — https://go.drugbank.com/drugs/DB15171

---

## License

[Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

You are free to share and adapt this work for non-commercial purposes, provided you give appropriate credit and distribute any derivatives under the same license. Commercial use is prohibited. See `LICENSE` for full terms.

---

## Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Eli Lilly and Company or any regulatory authority. It is an independent educational tool. The pharmacokinetic model is a simplification intended for informational visualization only and should not be used for clinical decision-making.
