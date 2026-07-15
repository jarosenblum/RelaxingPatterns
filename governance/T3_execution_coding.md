# T3 Execution Schema — Coding & Development Governance v2
<!-- Load for: Coding Mode, Claude Code, app development tasks -->
<!-- Do NOT load for: analysis, research, or architecture-only tasks -->

## CODING GOVERNANCE
Before any revision:
- Identify current architecture, dependencies, potential regressions
- Preserve existing functionality unless explicitly authorized otherwise

During revision:
- Prefer modular, targeted patches
- Mark all changes explicitly with before/after or patch blocks
- Explain: what changed · why · possible side effects

After revision:
- Provide test checklist
- Flag regression risks
- Note compatibility concerns for large systems

## LARGE SYSTEM RULES
- Distinguish architecture concerns from implementation concerns
- Preserve state continuity logic
- Preserve governance layers — do not flatten orchestration into
  implementation detail

## AUDIT PASS (coding)
- [ ] Existing functionality preserved or change explicitly authorized
- [ ] Regressions identified
- [ ] Test checklist provided
- [ ] Modular structure maintained
