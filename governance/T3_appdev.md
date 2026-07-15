# T3 Protocol — App/Software Dev v1
<!-- Load for: coding, build, and deployment tasks in scope for an active
     project. Referenced from T2 Domain Registry: App/Software Dev. -->

## STATUS
"Static Site / GitHub Pages" and "SwiftUI" are both populated and active.
Streamlit and Supabase are listed in T2 as anticipated key schemas but
have no project behind them yet; do not treat those two headers as
settled specs.

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

## SCHEMA: SWIFTUI
<!-- Active project: RelaxingPatterns app. Populated from direct source
     read, 2026-07-15, main branch — not from the parked
     feature/breath-aware-ambience branch. -->

### Module boundaries
- `RelaxingPatternsApp.swift` — `@main` entry point. Single `WindowGroup`
  wrapping `ContentView()`. No app-level state; all state lives in the
  managers below or in `ContentView` itself.
- `ContentView` — the main (and only) view. **Its source file is
  `RelaxingPatterns/if.swift`**, not `ContentView.swift` — the file was
  renamed at some point but the type name and internal header comment
  still say `ContentView.swift`. Compiles fine (Swift doesn't require
  filename/type-name match), but the filename is misleading. Recommend
  renaming the file to `ContentView.swift` to match its contents — flagged
  here rather than done automatically, since it's a live build file.
- `AmbientAudioManager` (`RelaxingPatterns/AmbientAudioManager.swift`) —
  singleton (`.shared`), `@MainActor`, owns the `AVAudioEngine` graph:
  per-`AmbientState` looping player nodes → mixer → 2-band EQ → reverb →
  main mix. Crossfades between states on `transition(to:)`, drifts EQ/
  reverb "evolution" targets over elapsed session time via a 1s timer.
  Also hosts `ToneGroupManager` (separate singleton in the same file) for
  one-shot tone playback that ducks the ambient bed.
- `TextCueManager` (`RelaxingPatterns/TextCueManager.swift`) — singleton,
  `ObservableObject`, `@MainActor`. Drives the reflective text-cue
  sequence (opening cues → orientation cues → milestone/sparse cues) on a
  5s tick timer, and is the thing that calls
  `AmbientAudioManager.shared.updateEvolution(elapsed:)` — i.e. the audio
  "evolution" arc is paced by the text-cue session clock, not by its own
  independent timer origin.

### State management pattern
No `@StateObject`/`@ObservedObject` wiring observed in `ContentView`'s
visible header — `TextCueManager` is `ObservableObject` but is accessed
via `.shared` (singleton), not injected as an environment/observed
object, in the code read so far. `AmbientAudioManager` is a plain
singleton (not `ObservableObject`) — it's driven imperatively
(`transition(to:)`, `updateEvolution(elapsed:)`), not observed by SwiftUI.
Confirm this fully against `if.swift`'s full body before treating it as
settled — only the file header and shared utilities were read for this
pass, not the entire view body.

### Audio architecture
- Ambient loop selection is a hardcoded dictionary in
  `AmbientAudioManager.loadLoops()` mapping `AmbientState` → `.m4a`
  filename (`ambient_segment_0N_...`). This is the actual live source of
  truth for state→file mapping.
- `RelaxingPatterns/File.txt` looks like the same mapping but is **not
  read by any code** (confirmed via full-source grep) and is **stale
  relative to the real mapping** (it lists `ambient_segment_05_205s`;
  the code and bundled asset are `ambient_segment_05_25s`). It's a design
  note, not config, and happens to be bundled into the app as a resource
  only because it sits inside the Xcode-synchronized `RelaxingPatterns/`
  folder. Recommend excluding it from target membership or moving it
  outside `RelaxingPatterns/` — not done automatically, since it changes
  target membership.
- `#if DEBUG` hooks (`restorePlaybackAfterDebugMicStop`,
  `recoverAmbientAfterDebugMicStart`) reference a "debug mic" concept —
  these are vestiges of the breath-aware microphone experiment that also
  left a leftover `INFOPLIST_KEY_NSMicrophoneUsageDescription` entry in
  `project.pbxproj` (see migration plan). DEBUG-gated, so no release
  impact, but they're dead weight on `main` tied to the parked branch's
  concept — candidate for removal in a future cleanup pass, not part of
  this migration's scope.

### Build system note
This project uses Xcode's file-system-synchronized groups (Xcode 16+),
not explicit `PBXBuildFile` entries. The **entire `RelaxingPatterns/`
folder is auto-included in the build** — anything placed inside it is
compiled or bundled automatically, with no separate step to add it to a
target. This is why the two root-level duplicate files
(`AmbientAudioManager.swift` mislabeled-`ContentView` duplicate,
`if_audio_integrated.swift`) were confirmed **not** part of the build —
they sit outside the synchronized root and were never referenced
anywhere in `project.pbxproj`.

### Task mode mapping (per T2 Task Mode Registry)
| This project's work | Maps to T2 mode |
|---|---|
| Changing audio state machine / crossfade behavior | Architecture |
| Adding a SwiftUI view or manager | Architecture, then Coding (T3_execution_coding.md) |
| Reviewing a code change against this schema | Audit |

## SCHEMA: STREAMLIT (stub)
Not populated — no active Streamlit project in scope yet.

## SCHEMA: SUPABASE (stub)
Not populated — no active Supabase project in scope yet.
