# DESIGN SYSTEM

## Visual Identity
- **Theme:** Ultra-premium dark mode. Restrained warm-paper tones for highlights and glassmorphic overlays.
- **Palette:**
  - Background: HSL(224, 25%, 12%) - Deep Slate Blue
  - Panel: HSL(224, 25%, 16%, 0.8) - Translucent glass
  - Primary Accent: HSL(142, 70%, 45%) - Emerald Mint (Active/Focus state)
  - Secondary Accent: HSL(32, 95%, 60%) - Solar Amber (Pause/Rest state)
  - Text Primary: HSL(210, 40%, 98%) - Crisp Off-White
  - Text Secondary: HSL(215, 20%, 65%) - Muted Gray
- **Typography:**
  - Font Family: Inter, System-UI, sans-serif
  - Headline Font: Outfit or system serif for high-contrast numeric layouts.

## Design Tokens & System
- **Spacing Scale:** Modular spacing based on 4px grid (4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px).
- **Transitions:** Easing `cubic-bezier(0.16, 1, 0.3, 1)` (ultra smooth out-expo) with a duration of `300ms` for interactive states.

## Visual Rules
- **Anti-Slop:** No default browser borders. Clean shadows using multi-layered ambient occlusions. Consistent rounded corners (`12px` or `16px`).
- **High Craft:** Subtle backdrop-filter blur (`12px`) on all dialogs and cards to create depth.
