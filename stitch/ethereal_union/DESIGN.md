# Design System Document: High-End Editorial Wedding Experience

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Concierge"**
This design system moves away from the "app-like" utility of standard wedding planners and toward the feeling of a bespoke, high-end editorial magazine. We are not just building a tool; we are designing a digital heirloom. 

To achieve this, the system breaks the "template" look through **Intentional Asymmetry** and **Tonal Depth**. Instead of centering everything on a rigid grid, we use overlapping elements—such as a serif headline partially masking a high-quality image—and dramatic typography scales to create a sense of luxury and breathing room.

## 2. Colors & Surface Architecture
The palette is a dialogue between the warmth of soft cream, the prestige of champagne gold, and the gravity of deep romantic burgundy.

### The "No-Line" Rule
Traditional 1px borders are strictly prohibited for sectioning. Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a `surface-container-low` section should sit directly on a `surface` background to define its start and end.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine paper. 
- **Base Layer:** `surface` (#fbf9f1) for the main page background.
- **Content Blocks:** Use `surface-container-low` (#f5f4ec) for large content areas.
- **Interactive Cards:** Use `surface-container-lowest` (#ffffff) to make interactive elements "pop" with a crisp, clean feel.

### The "Glass & Gradient" Rule
To add "soul" to the digital interface, use subtle linear gradients for primary actions. A transition from `primary` (#570013) to `primary_container` (#800020) at a 135-degree angle provides a velvet-like depth that flat color cannot match. For floating navigation or overlays, apply **Glassmorphism**: use `surface` at 80% opacity with a `20px` backdrop-blur to allow imagery to bleed through softly.

## 3. Typography: The Editorial Voice
Our typography pairing is designed to mimic a high-fashion masthead.

- **Display & Headlines (Noto Serif):** These are our "Statement" pieces. Use `display-lg` for names or event titles with tight letter-spacing (-0.02em) to evoke a sense of premium craftsmanship.
- **Body & Labels (Manrope):** A modern, clean sans-serif that ensures high legibility against the ornate headlines.
- **Hierarchy as Brand:** Always favor extreme contrast. Pair a `display-md` headline with a `label-md` in all-caps (0.1em letter-spacing) to create an authoritative, curated look.

| Role | Font Family | Size | Intent |
| :--- | :--- | :--- | :--- |
| **Display-LG** | Noto Serif | 3.5rem | Hero moments, Initials |
| **Headline-MD** | Noto Serif | 1.75rem | Section titles |
| **Body-LG** | Manrope | 1rem | Primary reading text |
| **Label-MD** | Manrope | 0.75rem | Metadata, Uppercase headers |

## 4. Elevation & Depth
We eschew heavy shadows in favor of **Tonal Layering**.

- **The Layering Principle:** Depth is achieved by stacking tiers. Place a `surface-container-lowest` card on a `surface-container` background. This creates a "soft lift" that feels architectural rather than digital.
- **Ambient Shadows:** If a floating element (like a FAB or Menu) requires a shadow, use a "Wedding Glow":
  - `box-shadow: 0 12px 40px rgba(87, 0, 19, 0.06);` (A tinted shadow using the primary-dark hue).
- **The "Ghost Border":** Where containment is vital (e.g., input fields), use the `outline_variant` (#e0bfbf) at **20% opacity**. It should be felt, not seen.

## 5. Components

### Buttons
- **Primary:** Gradient fill (`primary` to `primary_container`), `on_primary` text, `DEFAULT` (0.25rem) radius for a sharp, sophisticated edge.
- **Secondary:** `outline_variant` ghost border (20% opacity) with `primary` text.
- **Tertiary:** Text-only, `label-md` styling, all-caps with 0.1em tracking.

### Cards & Lists
- **Rule:** Forbid the use of divider lines. 
- Use vertical white space (32px or 48px) to separate list items. 
- For cards, use a subtle background shift to `surface-container-highest` on hover to indicate interactivity.

### Input Fields
- Avoid "box" inputs. Use a "Minimalist Ledger" style: a `surface-container-low` background with a bottom-only `outline_variant` (40% opacity).
- Labels should use `label-md` in `secondary` (#735c00) to act as a gold accent.

### Signature Component: The "Gallery Mosaic"
A custom layout component for wedding photos using intentional asymmetry. Mix large vertical images with small horizontal ones, using `xl` (0.75rem) rounded corners to soften the high-quality photography.

## 6. Do's and Don'ts

### Do
- **Do** use whitespace as a luxury commodity. If in doubt, add more padding.
- **Do** use `secondary` (Champagne Gold) sparingly as an accent for icons, labels, or active states.
- **Do** ensure all transitions are "Long and Fluid" (e.g., 500ms ease-in-out) to mimic the grace of a bridal procession.

### Don't
- **Don't** use 100% black text. Always use `on_surface` (#1b1c17) for a softer, premium contrast.
- **Don't** use "Standard" 4px rounded corners for everything. Use `none` for a more brutalist/editorial look on buttons, and `full` only for small utility chips.
- **Don't** use drop shadows on text. Let the typography speak through its weight and color.