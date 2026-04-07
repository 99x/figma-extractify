---
name: extractify-security-audit
description: "Use this skill whenever the user wants to run a security audit on the figma-extractify project using the ESAA-Security framework. Triggers on: '/extractify-security-audit', 'run security audit', 'security audit', 'audit security', 'check for vulnerabilities', 'run esaa security', 'esaa audit', 'security check', 'pentest', 'vulnerability scan', 'check security issues', 'find security problems', or any request to evaluate the security posture of this project."
user-invocable: true
argument-hint: "[audit label, e.g. post-fix validation]"
---

# Extractify Security Audit — ESAA-Security Pipeline

Executes a full 4-phase security audit of the figma-extractify project using the [ESAA-Security](https://github.com/elzobrito/esaa-security) framework (16 domains, 95 checks). Produces a numbered audit directory under `security-audits/` at the monorepo root.

## Before starting

1. Read `security-audits/README.md` — audit index and directory convention
2. Determine the next audit number: count existing `AUDIT-NNN` directories and increment
3. Create the output directory: `security-audits/AUDIT-NNN/reports/{phase1,phase2/results,phase3,phase4,final}/`

## Framework reference

ESAA-Security covers **16 security domains** organized in **4 phases**:

| Phase | Tasks | Output |
|---|---|---|
| Phase 1 — Reconnaissance | SEC-001 to SEC-003 | Tech stack, architecture map, data flow diagram, attack surface inventory |
| Phase 2 — Audit Execution | SEC-010 to SEC-025 | One `{domain}-audit.md` per domain + `results/SEC-NNN.json` |
| Phase 3 — Risk Classification | SEC-030 to SEC-032 | vulnerability-inventory.json, classified-vulnerabilities.json, risk-matrix.json, risk-matrix.md |
| Phase 4 — Reporting | SEC-040 to SEC-043 | technical-remediations.md, best-practices.md, executive-summary.md, final report |

## 16 Security Domains (Phase 2)

| Domain | File | Checks |
|---|---|---|
| Secrets & Configuration | `secrets-config-audit.md` | SC-001 to SC-008 |
| Authentication | `authentication-audit.md` | AU-001 to AU-008 |
| Authorization | `authorization-audit.md` | AZ-001 to AZ-006 |
| Input Validation | `input-validation-audit.md` | IV-001 to IV-007 |
| Data Security | `data-security-audit.md` | DA-001 to DA-005 |
| Dependencies | `dependencies-audit.md` | DS-001 to DS-006 |
| API Security | `api-security-audit.md` | AP-001 to AP-007 |
| File Upload | `file-upload-audit.md` | FU-001 to FU-006 |
| Session Security | `session-security-audit.md` | SS-001 to SS-006 |
| Cryptography | `cryptography-audit.md` | CR-001 to CR-005 |
| Infrastructure | `infrastructure-audit.md` | IF-001 to IF-006 |
| AI/LLM Security | `ai-llm-security-audit.md` | AI-001 to AI-005 |
| Security Headers | `security-headers-audit.md` | SH-001 to SH-005 |
| Logging & Monitoring | `logging-monitoring-audit.md` | LM-001 to LM-005 |
| DevSecOps | `devsecops-audit.md` | DO-001 to DO-006 |
| Frontend Security | `frontend-security-audit.md` | FE-001 to FE-004 |

## Execution rules

**For each check, always:**
1. Run the concrete command (grep, find, read file) — never assume
2. Record exact evidence: file path, line number, command output
3. Apply objective pass/fail criteria — no subjective judgment
4. If no surface exists for a domain (e.g., no database → SQL injection N/A), mark as N/A with justification
5. Never invent vulnerabilities — if you can't find evidence, the check passes

**Status values:** `pass` | `fail` | `partial` | `na`

**Severity:** `CRITICAL` | `HIGH` | `MEDIUM` | `LOW` | `INFO`

## Phase 1 — Reconnaissance

Produce 4 files in `reports/phase1/`:

### tech-stack-inventory.md
- All languages, frameworks, libraries with versions (from package.json, pyproject.toml, etc.)
- Infrastructure (Docker, CI/CD, cloud services)
- External integrations and authentication methods

### architecture-map.md
- System components and their roles
- Trust boundaries diagram (ASCII)
- Trust zones table (Untrusted → Trusted → High Trust)
- Data flows between components

### data-flow-diagram.md
- Primary data flows (numbered, with source → transform → destination)
- External data boundaries table (protocol, auth, data transmitted)
- Secrets and credentials inventory (location, in repo?, risk level)

### attack-surface-inventory.md
- Attack surface classification table (surface present? highest risk?)
- Per-surface analysis with specific findings
- Summary table by risk level

## Phase 2 — Audit Execution

For each of the 16 domains, produce `reports/phase2/{domain}-audit.md`:

```markdown
# {Domain} Audit — SEC-NNN

**Audit date:** YYYY-MM-DD
**Playbook:** {domain} ({XX-001 to XX-NNN})
**Auditor:** ESAA Security Agent (PARCER)

---

## XX-001: {Check name} — {PASS|FAIL|PARTIAL|N/A}

**Evidence:**
[concrete grep/read output or code snippet]

[Analysis]

**Status:** PASS|FAIL|PARTIAL|N/A

---
## Summary

| Check | Status | Severity |
|---|---|---|
| XX-001 ... | PASS | — |
```

Also produce `reports/phase2/results/SEC-NNN.json`:
```json
{
  "task_id": "SEC-NNN",
  "domain": "{domain}",
  "checks_total": N,
  "checks_pass": N,
  "checks_fail": N,
  "checks_partial": N,
  "checks_na": N,
  "worst_severity": "MEDIUM",
  "results": [
    {
      "check_id": "XX-001",
      "check_name": "...",
      "status": "pass|fail|partial|na",
      "severity_if_fail": "CRITICAL|HIGH|MEDIUM|LOW",
      "evidence": {
        "files": ["path/to/file"],
        "lines": ["42: offending code"],
        "commands_output": ["grep output"],
        "description": "..."
      },
      "remediation": "..."
    }
  ]
}
```

## Phase 3 — Risk Classification

### vulnerability-inventory.json
All `fail` and `partial` findings from Phase 2, each with:
- `id`: VULN-NNN (sequential)
- `title`, `domain`, `check_id`, `severity`, `status`, `files`, `lines`
- `description`: technical explanation
- `remediation`: concrete fix
- `effort`: time estimate

### classified-vulnerabilities.json
Each vulnerability with:
- OWASP Top 10 2021 category
- CIA triad impact (`confidentiality`, `integrity`, `availability`: LOW|MEDIUM|HIGH|NONE)
- `likelihood` (1–5), `impact` (1–5), `risk_score` (L×I), `risk_level`
- `justification`: why this severity, not higher/lower
- `false_positive_risk`: assessment of whether finding is genuine

### risk-matrix.md
```markdown
## Scoring Methodology
[Likelihood × Impact table]
[Score → Risk Level table]

## Risk Matrix (All Findings)
| ID | Finding | Likelihood | Impact | Score | Level | Domain |
[all findings sorted by score descending]

## Heatmap (ASCII)
[5×5 grid with vulnerability IDs plotted]

## Top 5 Risks by Score
## Risk by Domain (CRITICAL/HIGH/MEDIUM/LOW counts)
## Domain Scores (deductions from 100)
## Overall Score
## Residual Risk
```

### risk-matrix.json
Structured version of the risk matrix.

## Phase 4 — Reporting

### technical-remediations.md
For each CRITICAL and HIGH finding (then MEDIUM), provide:
- File path(s)
- Step-by-step fix with code snippets
- Time estimate

### best-practices.md
Per applicable domain:
- OWASP / NIST / CIS references
- Table: Best Practice | Reference | Project Status
- Recommended practice for this project

### executive-summary.md
- Overall score (0–100) with domain breakdown table
- Security posture summary (what works, what needs attention)
- Top 5 risks (numbered, with score, description, business impact, remediation effort)
- Finding count by severity
- Recommended action plan (Immediate / Short term / Medium term / Long term)

### final/security-audit-report.md
Consolidated report combining all phases:
- Executive summary section
- Phase 1 summary
- Phase 2 domain results table
- Phase 3 risk matrix table
- Phase 4 remediation plan
- Full artifact index

## After completing all phases

1. Update `security-audits/README.md` — add a row to the audit history table with: audit number, directory link, date, score, finding counts
2. Report to the user: overall score, top 3 risks, estimated remediation effort

## Output checklist

- [ ] `reports/phase1/` — 4 files generated
- [ ] `reports/phase2/` — 16 domain audit .md files
- [ ] `reports/phase2/results/` — structured JSON results
- [ ] `reports/phase3/` — 4 files (2 .json + 1 .md + 1 .json)
- [ ] `reports/phase4/` — 3 files
- [ ] `reports/final/security-audit-report.md`
- [ ] `security-audits/README.md` updated with new audit entry
