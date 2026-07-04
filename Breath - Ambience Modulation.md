FEATURE: BREATH-AWARE AMBIENCE MODULATION

PURPOSE

Use breathing only as a gentle ambience input, not as assessment, coaching, diagnosis, or performance feedback.

CORE PRINCIPLE

The app does not judge breathing quality. Breath rhythm may only be used to subtly shape the environment.

Breathing is not a score.
Breathing is an environmental signal.

PHASE 1 SCOPE: GUIDED BREATH CYCLE ONLY

Implement Phase 1 only.

Do not add microphone detection yet.

REQUIREMENTS

- Add a setting toggle: "Breath-Aware Ambience"
- Add a guided breathing visual/audio cycle without microphone input
- Create a normalized ambience signal:

    breathPhase: Double // 0.0 to 1.0

- Use breathPhase to subtly modulate:
    - particle expansion / contraction
    - background gradient breathing
    - audio reverb, warmth, or shimmer intensity if available

BEHAVIOR

- If the feature is disabled, preserve the existing baseline ambience.
- If the feature is enabled, ambience should gently "breathe" using a slow guided cycle.
- Modulation must be subtle and should not replace the existing particle/audio system.

TARGET RHYTHM
- Apply a 10-second cycle
- Default guided cycle: 4-second inhale, 1-second pause, 5-second exhale

Implementation should support future alternate cycles
through configuration without code changes.

ALLOWED EFFECTS

1. Slightly slow or soften particle motion during the calm portion of the cycle.
2. Gently expand/contract the background gradient with the breath cycle.
3. Add subtle audio warmth, shimmer, or reverb depth during slower portions.
4. Reduce visual/audio stimulation during faster or transitional portions.
5. Fade back to baseline when disabled or unavailable.

DISALLOWED EFFECTS

1. Do not display "you are breathing wrong."
2. Do not label anxiety, stress, panic, dysregulation, or health status.
3. Do not calculate or display respiratory rate.
4. Do not store raw audio.
5. Do not require breath detection for core app use.
6. Do not add microphone permission or microphone input in Phase 1.

USER-FACING LANGUAGE

Use:

"Breath-aware ambience gently follows a slow breathing rhythm. It is intended only for relaxation."

Avoid:

- measured breathing
- respiratory rate
- stress detection
- anxiety detection
- breathing quality
- performance

ACCEPTANCE CRITERIA

- App builds successfully.
- Existing animation remains intact.
- Existing audio behavior remains intact.
- Feature can be enabled and disabled.
- When disabled, current baseline ambience is unchanged.
- Modulation is subtle.
- No microphone permission is requested.
- No medical, anxiety, stress, or dysregulation claims appear in the UI.
- The breathing cycle must remain functional even when particle density, motion, audio, or future ambience features are changed independently.

IMPLEMENTATION ARCHITECTURE GUIDANCE

Create a small breath cycle model rather than hard-coding timing directly into views.

Preferred structure:

BreathCycle:
- inhaleDuration
- pauseDuration
- exhaleDuration
- totalDuration

Default cycle:
- inhale: 4.0 seconds
- pause: 1.0 second
- exhale: 5.0 seconds

Expose one normalized output:

breathPhase: 0.0 to 1.0

Visual and audio systems should consume breathPhase.
They should not independently calculate breath timing.

Reason:
This keeps breath timing centralized and makes future alternate cycles possible without rewriting particle, gradient, or audio code.

TICKET SEQUENCE

Ticket 1: Breath Phase Engine
Implement Ticket 1 only from the Breath-Aware Ambience Modulation spec.
- Add guided breath phase engine only.
- No UI effect yet.

Create a centralized BreathCycle model with:
- inhaleDuration
- pauseDuration
- exhaleDuration
- totalDuration

Default cycle:
- inhale: 4.0
- pause: 1.0
- exhale: 5.0

Expose:
- breathPhase: Double from 0.0 to 1.0

Do not connect this to UI, particles, gradient, audio, settings, microphone, permissions, or user-facing copy yet.

Acceptance criteria:
- App builds.
- Existing animation and audio behavior are unchanged.
- Breath timing is centralized and configurable.


Ticket 2: Visual Modulation
- Connect breathPhase to particle and background ambience only.

Ticket 3: Audio Modulation
- Connect breathPhase to subtle audio ambience parameters only.

Ticket 4: Settings and Copy
- Add setting toggle and explanatory copy.

Ticket 5: Future Spike Only
- Experimental microphone-based estimated rhythm modulation.
- Separate branch only.
- Not part of the current implementation.