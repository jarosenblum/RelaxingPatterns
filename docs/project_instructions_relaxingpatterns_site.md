# Project Instructions — RelaxingPatterns Website

## 1. Context
RelaxingPatterns is an iOS meditation/relaxation app (built in Codex,
possibly migrating to Claude Code). This project builds the app's public
web presence: a 3-page static site, hosted on GitHub Pages. This is a
distinct project from any NSF/lit-review work — no shared schema state,
though both draw on the same root T1/T2 governance files.

Recommended environment: **Claude Code** (CLI or desktop), not Cowork.
Rationale: this is a git-native build-and-deploy task, not a multi-tool
knowledge-orchestration task. If dev later moves fully to Claude Code for
the app itself, the site repo can live alongside it or as a sibling repo.

## 2. Source material (from app description provided)
> RelaxingPatterns is a gentle interactive experience designed to
> encourage brief moments of calm. Create soft patterns of light with
> simple taps and gestures while ambient sound and evolving visuals invite
> you to slow down, pause, and explore without goals or pressure.

Features to draw from:
- Flowing patterns from simple touch interactions
- Calm ambient audio responsive to interaction
- Multiple visual moods and color palettes
- Gentle reflective prompts
- Designed for short or long sessions

Compliance line (verbatim, must appear on Support page):
> RelaxingPatterns is intended for relaxation and enjoyment. It is not a
> medical device and is not intended to diagnose, treat, or prevent any
> medical condition.

## 3. Design direction (derived from provided screenshots)
- Dark background, soft blurred color-orb gradients (blue/purple/pink/
  green), no hard edges — the site should echo this rather than use a
  generic light SaaS template.
- Short, calm, second-person copy in the app's own voice: e.g. "Tap
  slowly," "You are Ok. This is all there is right now." The site's tone
  should match — sparse, unhurried, no urgency language, no growth-hacky
  CTAs ("Download NOW," exclamation points, etc.).
- Mode chips visible in the screenshots (Calm / Flow / Mood / Reset) are a
  useful visual motif for the marketing page if you want to preview the
  in-app experience without reproducing app UI wholesale.

## 4. Site structure (3 pages)

### Home
- Hero: app name, one-line description, App Store badge/link (placeholder
  until the app is live)
- 3-4 feature highlights (from source material above)
- Visual: a soft gradient/orb treatment echoing the app itself (CSS
  gradients, not a screenshot crop, to keep it lightweight and on-brand)
- Footer nav to Marketing and Support

### Marketing
- Fuller pitch: what the experience is, who it's for, why it's different
  from typical meditation apps ("without goals or pressure")
- Feature detail (expand each bullet from source material)
- Optional: press/App Store quote section (leave as placeholder structure
  until real quotes exist — do not fabricate reviews or quotes)

### Support
- FAQ (start minimal: "How do I use it," "Does it need sound on,"
  "Is my data private" — expand once real user questions exist)
- Contact method (placeholder until a real support email/form is decided)
- Compliance line (verbatim, see Section 2)
- Privacy policy link (placeholder if not yet written)

## 5. Technical approach
- Plain HTML/CSS/minimal JS. No framework unless page count grows past 3
  or shared-layout maintenance becomes painful.
- Shared header/nav/footer factored out (even simple `<template>`/JS
  include, or a tiny static-site generator like Eleventy, if repetition
  across 3 files becomes annoying — not required at this scale).
- No backend, no forms requiring a server (contact = mailto: or a
  third-party form service if wanted later).

## 6. Deployment (GitHub Pages)
1. New repo (name TBD — suggest `relaxingpatterns-site` or similar)
2. Choose one:
   - `/docs` folder on `main`, Pages source set to `main /docs`
   - dedicated `gh-pages` branch
3. Enable Pages in repo settings once first commit is pushed
4. Custom domain (optional, later): DNS CNAME + repo settings, decoupled
   from site structure

## 7. Open items / assumptions (flag before building)
- App Store link: not live yet — use placeholder, don't fabricate a URL
- Support contact: needs a real address/form before Support page ships
- Privacy policy: not provided — needs either a real doc or explicit
  placeholder, not invented text
- Repo name and GitHub account/org destination: unspecified

## 8. Migration note
If iOS app development later moves to Claude Code, this site project can
either stay standalone or move into the same workspace — no structural
dependency either way. T3_appdev.md's Static Site schema is written to
apply regardless of which repo layout is chosen.
