---
name: Imperial Jade & Gold
colors:
  surface: '#131411'
  surface-dim: '#131411'
  surface-bright: '#393936'
  surface-container-lowest: '#0e0f0b'
  surface-container-low: '#1b1c19'
  surface-container: '#1f201c'
  surface-container-high: '#2a2a27'
  surface-container-highest: '#343531'
  on-surface: '#e4e2dd'
  on-surface-variant: '#c0c9c3'
  inverse-surface: '#e4e2dd'
  inverse-on-surface: '#30312d'
  outline: '#8a938e'
  outline-variant: '#404945'
  surface-tint: '#9ed1bd'
  primary: '#9ed1bd'
  on-primary: '#00382a'
  primary-container: '#1b4d3e'
  on-primary-container: '#8abda9'
  inverse-primary: '#376757'
  secondary: '#e9c349'
  on-secondary: '#3c2f00'
  secondary-container: '#af8d11'
  on-secondary-container: '#342800'
  tertiary: '#ffb4ab'
  on-tertiary: '#690004'
  tertiary-container: '#8f0009'
  on-tertiary-container: '#ff9589'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#baeed9'
  primary-fixed-dim: '#9ed1bd'
  on-primary-fixed: '#002117'
  on-primary-fixed-variant: '#1d4f40'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#ffdad5'
  tertiary-fixed-dim: '#ffb4ab'
  on-tertiary-fixed: '#410002'
  on-tertiary-fixed-variant: '#930009'
  background: '#131411'
  on-background: '#e4e2dd'
  surface-variant: '#343531'
  deep-jade: '#002117'
  bright-gold: '#ffe088'
  antique-paper: '#fffdf7'
  stamp-red: '#ba1a1a'
  glow-mint: '#8abda9'
typography:
  display-gold:
    fontFamily: Epilogue
    fontSize: 52px
    fontWeight: '800'
    lineHeight: '1.0'
    letterSpacing: -0.05em
  heading-lg:
    fontFamily: Epilogue
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  ledger-sm:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-xs:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
  serial-number:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    letterSpacing: 0.2em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  margin-page: 20px
  gutter-grid: 12px
  stack-gap: 8px
  unit: 4px
  padding-card: 32px
---

## Brand & Style
The brand identity is "Imperial Jade & Gold," a luxury-tier aesthetic that blends traditional East Asian opulence with high-stakes digital gaming. It evokes the feeling of an exclusive, high-value contract or a royal decree.

The design style is **Tactile & Skeuomorphic**, utilizing rich textures (rice paper, natural fibers), physical metaphors (vermilion stamps, embossed gold), and atmospheric depth (water ripples, radial glows). It aims for an emotional response of prestige, authority, and excitement. Every interaction should feel like handling a physical, high-value object.

## Colors
The palette is rooted in a "Fidelity" dark mode where the background is a deep, immersive jade green.

- **Primary (Jade):** Used for the base environment and core action surfaces. It represents stability and value.
- **Secondary (Gold):** Used for status symbols, borders, and high-impact typography. It implies wealth and "winning."
- **Tertiary (Vermilion):** Reserved for "official" seals and stamps, providing a sharp contrast and a sense of finality/verification.
- **Neutral (Paper):** A warm, off-white used as a canvas for interactive "documents" to ensure legibility and a tactile paper feel.

## Typography
The typography system uses a mix of expressive display faces and technical monospaced fonts to reinforce the "Contract" metaphor.

- **Epilogue (Display):** Used for titles and headers. It should feel embossed or metallic when used in gold.
- **Manrope (UI/Body):** Used for standard information and labels, providing a modern, clean balance to the ornate environment.
- **JetBrains Mono (Technical):** Used for "Ledger" data, prices, and serial numbers to evoke the precision of a ledger or bank note.

## Layout & Spacing
The layout uses a **Contextual Fluid Grid** designed for mobile-first immersion.

- **Outer Margins:** Fixed at 20px to frame the central "artifact."
- **Central Artifact:** The primary content (Contract/Ticket) is centered vertically and horizontally, often with a slight rotation (1-2 degrees) to mimic a document placed on a desk.
- **Stacking:** Elements within cards use a tight 8px vertical rhythm for data pairs, while main sections are separated by 16-24px.

## Elevation & Depth
Depth is created through a combination of **Ambient Shadows** and **Skeuomorphic Layering**:

1.  **Level 0 (Environment):** Deep Jade radial gradient with rice-paper texture and animated "water ripple" blurs.
2.  **Level 1 (Paper Surface):** The "Contract" uses a heavy 30px shadow with an inner glow to simulate physical thickness. It features a natural-paper texture.
3.  **Level 2 (Interactive Elements):** Buttons use "extrusions" (solid bottom shadows) and metallic borders rather than standard blurs.
4.  **Level 3 (Stamps/Overlays):** Vermilion stamps are applied with a "multiply" blend mode to look like ink absorbed into the paper, sitting at the highest visual layer but interacting with the texture below.

## Shapes
The shape language is primarily **Geometric with Sharp Accents**.

- **Cards/Paper:** Use minimal rounding (soft corners) to maintain the look of cut paper.
- **Action Buttons:** Use a more pronounced `xl` (0.5rem) or `full` rounding for ergonomics.
- **Ornamentation:** Rectilinear borders with Greek-key or corner-bracket motifs are used to reinforce the traditional aesthetic.

## Components

### Buttons
- **Luxury Action Button:** High-contrast gradient (Deep Jade to Darker Jade), thick 3px Gold border, and a 4px solid drop-shadow that creates a "pressable" 3D effect. Text is uppercase or bold for authority.
- **Ghost/Minor Action:** Transparent background with gold-tinted outlines.

### Cards (The Contract)
- **Paper Finish:** Off-white background with `natural-paper` texture.
- **Ornamentation:** A decorative gold inner border (8px inset) with custom corner brackets.
- **Data Rows:** Dotted borders (`border-dotted`) for line items to simulate vintage receipts.

### Stamps & Seals
- **Vermilion Stamp:** High-contrast red (`#ba1a1a`), thick border, slightly rotated, using a Multiply blend mode.
- **Iconography:** Use Material Symbols Outlined, styled in Gold or Vermilion with a subtle drop shadow to feel like metallic pins or ink.

### Input/Display Fields
- Technical data is always displayed in `JetBrains Mono` to look like computer-generated "official" entries.