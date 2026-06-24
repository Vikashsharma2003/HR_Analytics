# HR Analytics — TechCorp India

End-to-end HR analytics pipeline and Power BI dashboard built on a synthetic 50,000-employee dataset spanning four source tables (employees, attendance, payroll, performance). Raw data → MySQL pipeline (raw → staging → business layer) → Power BI dashboard answering four real HR business questions.

> **Note:** This dataset is synthetic and built for portfolio/learning purposes. Findings demonstrate analytical methodology, not actual operational data from a real company.

---

## Business Problem

TechCorp India's HR Director needed data-driven answers to four questions before a quarterly board meeting:

1. **Attrition** — Which departments/roles have the highest attrition? Do long-tenure employees leave more than new joiners?
2. **Pay Fairness** — Are high performers paid more? Is there a gender pay gap?
3. **Productivity** — Is attendance linked to performance?
4. **Promotion Fairness** — Are high performers actually getting promoted?

---

## Dataset

| Table | Rows (raw) | Description |
|---|---|---|
| `employees` | 51,200 | Demographics, department, role, joining/exit dates, salary |
| `attendance` | 70,000 | Daily attendance % and work mode (2025) |
| `payroll` | 51,200 | Monthly gross salary, bonus, tax deduction (Jan–Apr 2025) |
| `performance` | 52,700 | Annual performance rating, promotion status, training hours (2022–2025) |

---

## Pipeline Architecture

```
Raw Layer (MySQL)
      ↓
Staging Layer — cleaning views (dedup, type casting, date normalization)
      ↓
Materialized Tables — for Power BI refresh performance
      ↓
Business Views — one per business question
      ↓
Power BI Dashboard
```

### Key Data Quality Decisions

| Issue Found | Rows Affected | Decision |
|---|---|---|
| Negative `monthly_salary` / `gross_salary` | 100 | `ABS()` applied — clear sign-entry error |
| Mixed date formats (3 formats across 2 columns) | — | `STR_TO_DATE` with `REGEXP` format detection |
| System default placeholder exit date (2025-01-10) | 194 of 195 | Set to `NULL` for Active employees only; 1 genuine exit on this date preserved after cross-checking against employee status |
| `attendance_percent` > 100% (impossible) | 150 | Set to `NULL` rather than capped — capping would have introduced false data |
| Duplicate rows (employee_id + period) across all 4 tables | 1,200–1,764 per table | `ROW_NUMBER()` deduplication, tie-break logic justified per table (e.g., kept highest bonus assuming re-evaluated entry) |
| Bonus exceeding gross salary | 2,126 (4.1%) | Set to `NULL` — applied the 10% data-quality threshold rule (>10% affected would require source investigation) |
| "On Leave" employees with a fixed exit_date | 1,068 | Set to `NULL` — exit_date is logically incompatible with an active-type status |

Full reasoning for each decision is documented inline in the SQL scripts.

---
## 
### Employee Overview Dashboard
![Employee Overview](HR_Analytics/screenshots/01_Overview.png)

## Key Findings

### 1. Performance Rating Is Disconnected From Every Reward Mechanism

Checked independently across four separate metrics:

| Metric | Range Across Rating 1–5 | Verdict |
|---|---|---|
| Average Salary | ₹101,647 – ₹102,319 | Flat |
| Average Bonus | ₹24,160 – ₹24,590 | Flat |
| Promotion Rate | 49.55% – 50.64% | Flat |
| Attendance % | 84.77% – 85.09% | Flat |

Four independent checks, the same conclusion every time. Training hours also showed no meaningful difference between Promoted (60.29 hrs) and Not Promoted (59.68 hrs) employees. This pattern — checked across pay, bonus, promotion, and attendance — suggests the performance review process is not currently influencing any tangible outcome.

### 2. Early-Tenure Attrition Gap

Active employees average **5.9 years** tenure, proving long-term retention is achievable. Employees who exited (Resigned, Terminated, or Absconded — Retired excluded as a natural exit) averaged only **3.2–3.3 years**. Combined with Finding 1, this points to a specific risk window: early-tenure employees have no visible incentive to stay past year 1–3.

### 3. Hidden Gender Pay Gap

The company-wide gender pay gap appears negligible (**0.24%**) — but this average conceals department-level swings of up to **±1.85%** in opposite directions:

- Sales: -1.85% (favors women)
- Human Resources: +1.63% (favors men)
- Information Technology: +1.55% (favors men)
- Finance: ~0.00%

Relying on the aggregate figure alone would have missed this entirely — pay equity needs to be checked at department level, not company level.

---

## Recommendations

1. Investigate why performance ratings don't influence pay or promotion — review whether the rating process itself is reliable.
2. Build early-tenure retention programs (years 0–3) rather than broad company-wide initiatives.
3. Audit pay equity at the department level — company-wide averages are not a reliable equity check.
4. Re-evaluate the link between training investment and promotion outcomes.

---

## Dashboard

5-page Power BI report:

| Page | Contents |
|---|---|
| Overview | Company-wide KPIs, headcount, gender split, exit trend, headline finding |
| Attrition Analysis | Attrition by department/role, tenure by exit status, gender breakdown |
| Fair Pay Analysis | Salary/bonus vs. performance rating, department-level gender pay gap, highest-paying roles |
| Attendance Analysis | Attendance vs. performance rating, department attendance trends |
| Promotion Fairness | Promotion rate by rating/department/gender, training hours comparison |

Includes a dedicated Report/Summary page consolidating all findings, recommendations, and data limitations.

---

## Data Limitations

- Attendance data covers 37,709 of 50,000 employees (75.4%) — analysis reflects this subset only.
- Payroll data spans January–April 2025 only — figures represent this 4-month period, not annual compensation.
- Performance reviews span 2022–2025; where an employee had multiple review years, the most recent available rating was used.
- Active employee tenure recalculates against the current date on each refresh; tenure for exited employees is fixed.
- This dataset is synthetic, built for demonstrating pipeline and analysis methodology.

---

## Tools Used

| Layer | Tool |
|---|---|
| Data storage & cleaning | MySQL (raw → staging → business layer) |
| Deduplication & transformation | SQL — `ROW_NUMBER()`, CTEs, `STR_TO_DATE`, `REGEXP` |
| Dashboard & visualization | Power BI (DAX measures, conditional formatting, custom theme) |

---

## Project Files

```
01_Raw_Data            — CSV FILE 
02_SQL File            — Raw, Clean and Business layer Sql query
03_screenshot          —images of dashboards
04_POWER_BI_Report      — Power bi dashboards and executive summary
```
