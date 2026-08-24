---
name: Celestial Romance
colors:
  surface: '#fff8f4'
  surface-dim: '#e1d8d3'
  surface-bright: '#fff8f4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fbf2ec'
  surface-container: '#f5ece6'
  surface-container-high: '#efe6e1'
  surface-container-highest: '#eae1db'
  on-surface: '#1f1b18'
  on-surface-variant: '#584239'
  inverse-surface: '#34302c'
  inverse-on-surface: '#f8efe9'
  outline: '#8c7167'
  outline-variant: '#dfc0b4'
  surface-tint: '#a53c00'
  primary: '#a53c00'
  on-primary: '#ffffff'
  primary-container: '#ff7a3d'
  on-primary-container: '#652200'
  inverse-primary: '#ffb598'
  secondary: '#9c4236'
  on-secondary: '#ffffff'
  secondary-container: '#ff8f7e'
  on-secondary-container: '#76261c'
  tertiary: '#76583d'
  on-tertiary: '#ffffff'
  tertiary-container: '#be9a7a'
  on-tertiary-container: '#4b321a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbcd'
  primary-fixed-dim: '#ffb598'
  on-primary-fixed: '#360f00'
  on-primary-fixed-variant: '#7e2c00'
  secondary-fixed: '#ffdad4'
  secondary-fixed-dim: '#ffb4a8'
  on-secondary-fixed: '#410100'
  on-secondary-fixed-variant: '#7d2b21'
  tertiary-fixed: '#ffdcbf'
  tertiary-fixed-dim: '#e6bf9d'
  on-tertiary-fixed: '#2b1703'
  on-tertiary-fixed-variant: '#5c4127'
  background: '#fff8f4'
  on-background: '#1f1b18'
  surface-variant: '#eae1db'
typography:
  display-lg:
    fontFamily: Libre Caslon Text
    fontSize: 48px
    fontWeight: '400'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-md:
    fontFamily: Libre Caslon Text
    fontSize: 36px
    fontWeight: '400'
    lineHeight: 44px
  headline-lg:
    fontFamily: Libre Caslon Text
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Libre Caslon Text
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
  headline-md:
    fontFamily: Libre Caslon Text
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-margin: 24px
  gutter: 16px
  section-gap: 40px
---

## Brand & Style

The design system is anchored in a **sophisticated and romantic** aesthetic, designed to bridge the gap between high-end editorial wedding stationery and functional digital management. The target audience includes both the organizing couple (Admin) looking for a stress-free, elegant planning experience and Guests who should feel a sense of warmth and celebration from the first interaction.

The style is a blend of **Modern Minimalism** and **Editorial Elegance**. It utilizes a generous amount of whitespace (Ivory/Cream), refined serif typography for a literary feel, and delicate floral accents to ground the digital experience in the physical reality of a wedding. The interface uses soft, organic shapes and translucent layers to evoke a sense of lightness and celebration.

**Key visual principles:**
- **Warmth:** Every interaction is bathed in soft, sunset tones.
- **Elegance:** High-contrast typography and gold accents provide a premium feel.
- **Accessibility:** While romantic, the Admin dashboard remains utilitarian with clear information hierarchy for high-stakes planning tasks.

## Colors

The palette is inspired by a Mediterranean golden hour. 

- **Primary (Orange):** Used for primary calls to action (RSVP, Save, Create) and critical active states.
- **Secondary (Salmon & Peach):** Used for supporting UI elements, progress bars, and illustrative backgrounds to create a soft, tonal depth.
- **Background (Ivory/Cream):** The canvas for the entire system, providing a softer, more historic feel than pure white.
- **Accent (Gold):** Reserved for decorative flourishes, icons, and premium "Admin" status markers.
- **Neutral (Warm Charcoal):** Used for body text and labels to ensure high legibility against the cream background while maintaining a softer contrast than black.

## Typography

The typography strategy pairs the timeless authority of **Libre Caslon Text** with the modern, approachable clarity of **Plus Jakarta Sans**.

- **Headlines:** Use Serif for all emotive and structural headings. This creates the "invitation" feel. Use `display-lg` specifically for the couple's names and primary event headers.
- **Body & Admin UI:** Use Sans-Serif for all data-heavy sections, guest lists, and form fields. It ensures the Admin dashboard remains efficient and readable.
- **Labels:** Small labels and metadata should use uppercase Sans-Serif with slight letter spacing for a refined, organized appearance.

## Layout & Spacing

The layout utilizes a **fluid grid** model with generous inner margins to evoke the feeling of centered stationery.

- **Desktop (Admin):** A 12-column grid with a fixed left-hand navigation. Dashboard widgets and tables should span 4, 6, or 12 columns.
- **Mobile (Guest & Admin):** A single-column flow with 24px side margins. Content cards use "safe areas" to ensure floral illustrations in the background do not interfere with text legibility.
- **Rhythm:** An 8px base unit is used for all internal component spacing. Section gaps are intentionally large (40px+) to maintain the minimalist, premium feel.

## Elevation & Depth

Hierarchy is achieved through **Tonal Layers** and **Ambient Shadows** rather than harsh borders.

1.  **Level 0 (Background):** Ivory base color (#FFF7ED).
2.  **Level 1 (Cards/Containers):** Pure white surfaces with an ultra-soft, diffused shadow (15% opacity of the Primary color) to create a warm glow rather than a grey drop shadow.
3.  **Overlays:** High-blur glassmorphism (backdrop-filter: blur(10px)) for mobile navigation bars and modals, allowing the background floral patterns to peek through.
4.  **Accents:** Gold flourishes and thin 1px Salmon-colored dividers are used to separate content without adding visual bulk.

## Shapes

The design system adopts a **Rounded** shape language to reflect the softness and organic nature of a wedding.

- **Standard Elements:** Buttons and input fields use a `0.5rem` radius.
- **Cards & Containers:** Large containers use `rounded-xl` (1.5rem) or even `2rem` for guest-facing RSVP cards to emphasize a welcoming, friendly atmosphere.
- **Specialty:** Media recording buttons and "Open Invitation" CTAs may use pill-shaped (fully rounded) geometry to stand out as primary interaction points.

## Components

### Buttons
- **Primary:** Solid Orange (#FF7A3D) with white text. Pill-shaped for Guest view, `rounded-lg` for Admin view.
- **Secondary:** Salmon (#FF8F7E) outline with 2px stroke.
- **Tertiary/Ghost:** Gold text with no background, used for "cancel" or "back" actions.

### Input Fields
- Soft Peach (#FFD6B3) backgrounds with a 1px Gold bottom border or full `rounded-lg` containers. Focus states should use a soft Salmon glow.

### Cards
- **Admin Dashboard:** White backgrounds, minimal borders, high use of typography for hierarchy.
- **Guest RSVP:** Feature a subtle floral header or corner illustration, using the Peach background (#FFD6B3) to differentiate from the main page flow.

### Tables & Lists
- **Guest Management:** Clean, zebra-striped rows using very faint Salmon (5% opacity) to distinguish lines without cluttering the view.

### Progress Indicators
- For the Guest "Media Upload" flow, use a custom Gold-tinted progress bar that fills with a sparkling or gradient effect to celebrate the completed action.

### QR Access
- The QR code should be framed in a Gold decorative border, presented on a pure white "Level 1" card to ensure scan accuracy while maintaining the brand aesthetic.