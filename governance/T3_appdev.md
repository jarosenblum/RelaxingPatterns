# T3 Protocol — App/Software Dev v1
<!-- Load for: coding, build, and deployment tasks in scope for an active
     project. Referenced from T2 Domain Registry: App/Software Dev. -->

## STATUS
Only the "Static Site / GitHub Pages" schema below is populated — it's the
only sub-domain with an active project. Streamlit, SwiftUI, and Supabase
are listed in T2 as anticipated key schemas but have no project behind them
yet; do not treat their headers below as settled specs.

## SCHEMA: STATIC SITE / GITHUB PAGES
<!-- Active project: RelaxingPatterns marketing/support/home site -->

### Scope
Multi-page static site (no backend, no build framework required unless a
project later needs templating at scale). Plain HTML/CSS/(minimal) JS is
the default; escalate to a static site generator only if page count or
shared-layout maintenance actually demands it.

### Structural invariants
1. Three-page ceiling unless the project brief explicitly expands scope:
   Home, Marketing, Support.
2. Shared layout/nav/footer must not duplicate markup across pages —
   partmaterialize via includes, a shared header/footer snippet, or a
   lightweight generator, even in a no-framework setup.
3. Design language derives from the product's own visual identity
   (see project instructions for the specific direction), not generic
   template defaults.
4. Legal/compliance line ("not a medical device...") is load-bearing copy,
   not filler — it must appear verbatim on the Support page and should not
   be paraphrased away in edits.

### Deployment invariants
1. GitHub Pages is the target host. Two viable deploy modes:
   - `/docs` folder on `main` (simplest, no Actions needed)
   - dedicated `gh-pages` branch (cleaner separation, marginally more setup)
2. Repo and deploy config should be decided once, in Claude Code, not
   re-litigated per session.
3. Custom domain (if added later) is a DNS + repo-settings change, not a
   site-structure change — keep these decoupled.

### Task mode mapping (per T2 Task Mode Registry)
| This project's work | Maps to T2 mode |
|---|---|
| Deciding site structure, page purposes, IA | Architecture |
| Choosing Cowork vs Claude Code vs plain build | Strategy |
| Reviewing a drafted page against the brief | Audit |

## SCHEMA: SWIFTUI (stub)
Not populated — no active SwiftUI project in scope yet.

## SCHEMA: STREAMLIT (stub)
Not populated — no active Streamlit project in scope yet.

## SCHEMA: SUPABASE (stub)
Not populated — no active Supabase project in scope yet.
