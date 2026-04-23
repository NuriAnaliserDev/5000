# Design System Specification: Enterprise Command Center

## 1. Overview & Creative North Star
### Creative North Star: "The Kinetic Observatory"
This design system moves away from the static, "dashboard-as-a-table" mentality. It adopts the philosophy of **Kinetic Light and Material Depth**. The goal is to create a "Military-Grade Mining Software" experience that feels like an advanced tactical interface—where data isn't just displayed, it is projected. 

By leveraging **intentional asymmetry**, we break the rigid corporate grid to guide the eye toward critical telemetry. We replace traditional structural dividers with **tonal layering** and **glassmorphism**, creating a digital environment that feels sophisticated, high-stakes, and immersive.

---

## 2. Colors: Tonal Architecture
The palette is built on a "Deep Space" foundation, using light not just as decoration, but as a functional indicator of system health and energy.

### Color Tokens
- **Background/Base:** `#0e0e0f` (The void upon which all data floats).
- **Primary (Neon Blue):** `primary: #6dddff` | `primary_container: #00d2fd`
- **Secondary (Emerald):** `secondary: #69f6b8` | `secondary_container: #006c49`
- **Tonal Tiers:** `surface_container_lowest: #000000` to `surface_container_highest: #262627`

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning. Boundaries must be defined solely through background shifts. A `surface_container_low` section sitting on a `surface` background provides all the definition required. If a container feels "lost," increase the tonal contrast between the parent and child, do not add a line.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. 
- **The Bedrock:** The main background (`surface`).
- **The Console:** Large functional areas using `surface_container_low`.
- **The Modules:** Actionable cards or data clusters using `surface_container_high`.
- **Floating HUDs:** Elements that require immediate focus should use `surface_bright` with a backdrop blur of 12px–20px.

### The "Glass & Gradient" Rule
Standard flat colors lack the "Military-Grade" polish. 
- Use **Glassmorphism** for all floating overlays (Modals, Tooltips, Popovers). Use `surface_variant` at 40% opacity with a `backdrop-filter: blur(16px)`.
- Use **Linear Gradients** for primary CTAs: `primary` to `primary_dim` at a 135-degree angle. This provides a "glowing filament" look rather than a flat plastic button.

---

## 3. Typography: Tactical Clarity
We pair the geometric precision of **Space Grotesk** for high-level data with the hyper-readability of **Inter** for operational text.

- **Display (Space Grotesk):** Used for "Big Numbers" and status headers. These should feel like readouts on a cockpit display.
- **Body (Inter):** Used for all technical logs, descriptions, and inputs. 
- **Letter Spacing:** Increase letter spacing by 0.05em for `label-sm` and `label-md` to mimic technical schematics.
- **Hierarchy:** High contrast in scale is encouraged. A `display-lg` metric (3.5rem) should sit confidently next to a `label-sm` (0.6875rem) unit descriptor to create an editorial, high-end feel.

---

## 4. Elevation & Depth
In a command center, depth equals importance. We achieve this through **Tonal Layering** rather than drop shadows.

### The Layering Principle
- Place a `surface_container_lowest` card on a `surface_container_low` section. This "recessed" look is ideal for data logs and secondary feeds.
- Place a `surface_container_highest` card on a `surface` background to create a "raised" tactile feel for primary controls.

### Ambient Shadows
Shadows should be rare. When used (e.g., for a floating command palette), use the **Ambient Glow** method:
- **Shadow Color:** `primary` at 8% opacity.
- **Blur:** 40px - 60px.
- This creates the illusion that the screen is projecting light onto the surface behind it.

### The "Ghost Border" Fallback
If accessibility requirements demand a container edge, use the **Ghost Border**:
- `outline_variant` at 15% opacity.
- **Stroke Width:** 1px.
- Never use 100% opaque borders; they shatter the glassmorphism illusion.

---

## 5. Components

### Buttons: The "Energy Cells"
- **Primary:** Gradient from `primary` to `primary_dim`. High-contrast `on_primary_container` text. Subtle outer glow on hover using `primary_fixed_dim`.
- **Secondary:** Transparent background with a `Ghost Border`. Text in `secondary`.
- **Corner Radius:** Use `md` (0.375rem) for a professional, technical look. Avoid `full` rounding unless it's a floating action button.

### Cards: The "Telemetry Modules"
- **Rules:** No dividers. Separate header from body using a slight background shift (e.g., `surface_container_highest` header on `surface_container_high` body).
- **Visuals:** Incorporate a 2px vertical "Accent Strip" of `secondary` or `primary` on the left edge to denote status.

### Data Visualizations: "Glowing Telemetry"
- All charts must use `primary` and `secondary` glow effects.
- Line charts should use a 2px stroke with a 4px blur layer underneath to simulate a CRT or neon filament.
- Grid lines in charts must use `outline_variant` at 10% opacity.

### Input Fields: "Tactical Entry"
- **Default State:** `surface_container_highest` background, no border.
- **Focus State:** 1px `Ghost Border` using `primary`. Internal glow using a subtle inner shadow of the `primary` color at 5% opacity.

### Additional Component: The "Status Pulse"
- A small 8px circle component. 
- Use `secondary` for "Nominal" and `error` for "Critical."
- Add a CSS animation "pulse" (scaling from 1.0 to 1.5 with 0% opacity) to signify real-time data streaming.

---

## 6. Do's and Don'ts

### Do
- **Do** use `surface_container` tiers to create depth without lines.
- **Do** lean into asymmetry. A large data visualization on the left balanced by three smaller status modules on the right feels "designed," not "templated."
- **Do** use `backdrop-filter: blur()` generously on overlays to maintain the glass aesthetic.
- **Do** use `secondary` (Emerald) for positive mining yields and system health.

### Don't
- **Don't** use standard "Dark Grey" (`#333`). Stick to the slate and matte black palette (`#0e0e0f`).
- **Don't** use 100% white for body text. Use `on_surface_variant` to reduce eye strain in mission-critical environments.
- **Don't** use sharp 90-degree corners. The `DEFAULT` (0.25rem) or `md` (0.375rem) radius provides a "machined" feel.
- **Don't** use dividers. If you need to separate content, use white space from the spacing scale or a tonal shift.