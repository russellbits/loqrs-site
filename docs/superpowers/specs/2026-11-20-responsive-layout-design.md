# Responsive layout for the LOQRS marketing page

Date: 2026-11-20
Status: design approved; spec awaiting review

## Problem

The home page does not collapse to mobile. At a 390px viewport
`document.documentElement.scrollWidth` is 1492px, so the page scrolls
sideways 3.8x instead of reflowing. Every top-level container is a fixed
pixel width, so no amount of breakpoint logic inside them can help.

Measured at 390px viewport, before any change:

| element | width | set by |
| --- | --- | --- |
| `div.site-border` | 1492px | `house.scss:37` `width: 1492px` |
| `main` | 1442px | `house.scss:52` `width: 1442px` |
| `section.lockers-row` | 1440px | `$lockers-row-max-width` |
| `.guide-grid` | 1410px | `max-width: 1442px` |
| `.input-group` | 1000px | `SignUp.astro:23` `width: 1000px` |

Three reported symptoms share this one root cause:

1. The guide does not stack. Its `flex-wrap: wrap` is set and correct, but
   wrapping needs a container narrower than four 260px steps plus gaps.
   At 1410px that never happens.
2. The coupon field does not visibly stack. Graffiti's `.stack-mobile`
   does fire at `width < 640px` and `.input-group` does compute
   `flex-direction: column`, but the 1000px box is off-screen.
3. The page scrolls sideways.

The locker row needs a decision rather than a fix: `LockersRow.astro`
composes two wide raster images and there is no mobile asset in the repo.

## Goals

- No horizontal scrolling at any viewport from 320px up.
- The guide renders 4 across on desktop, 2 across mid-width, 1 across on
  phones, without overflow at 320px.
- The coupon field stacks into a usable column on phones.
- The locker row serves a portrait graphic on phones and downloads only
  the graphic it shows.
- Desktop appearance is preserved, except for the headline centering fix
  described below.

## Non-goals

- No JavaScript breakpoint detection. Detection is CSS media queries and
  `<picture>` `media` attributes only.
- No changes to graffiti's internals. Its components and tokens stay as
  the source of truth for interactive elements.
- No new breakpoint tokens or a breakpoint mixin system. One breakpoint.
- No font changes, no art direction beyond the locker crop, no copy
  changes.

## Design

### 1. Fluid containers

Two rules change from fixed widths to fluid widths:

```scss
div.site-border {
    width: 100%;          // was: width: 1492px
    max-width: 1492px;    // new
}

main {
    width: 100%;          // was: width: 1442px
    max-width: 1442px;    // new
}
```

`div.site-border` has `padding: 25px` and 3px side borders, and the
document uses `box-sizing: border-box`, so its content box is
1492 - 50 - 6 = 1436px. `main` at `width: 100%` therefore resolves to
1436px, not the 1442px it is set to today.

That 6px difference is a bug being fixed, not a regression: `main`'s
fixed 1442px currently overflows its parent's 1436px content box by 6px.
Desktop narrows by 6px as a result, and the locker row narrows from
1440px to 1436px.

Worth knowing: the page overflows today at every viewport, desktop
included. At a 1442px viewport `site-border` is still 1492px, so
`scrollWidth` is 1492.

`.lockers-row` and `.guide-grid` already use `max-width` without a fixed
`width`, so they become fluid once their parent does. No change needed in
either rule.

### 2. Breakpoint

A single breakpoint at `40rem` (640px), matching graffiti's `.stack-mobile`
threshold (`width < 640px`). The form stack and the layout collapse then
happen at the same moment. There is no separate tablet breakpoint; the
guide's flex handles 4 to 2 to 1 on its own.

### 3. Guide columns

```scss
.guide-step {
    flex: 1 1 260px;      // was: flex: 1 1 0
    max-width: 320px;     // unchanged
    // min-width: 260px   // deleted
}
```

Deleting `min-width` matters at the narrow end. At a 320px viewport the
guide's content box is 200px: 320 minus 56 for `site-border`, minus 32 for
`.guide`'s padding, minus 32 for `.guide-grid`'s padding. A 260px minimum
makes each step 60px wider than its container. Flex centering splits the
spill evenly and keeps it inside the viewport, so it does not cause
horizontal scrolling, but the step breaks out of the guide's intended
inset on both sides. With a flex basis instead, a step that does not fit
wraps to its own line and flex-shrink takes it down to the available
width.

Expected column counts, computed from the flex basis of 260px and a 32px
gap: 4 across at 1442px, 3 across at 1024px, 2 across at 768px, 1 across
at 390px and at 320px.

The `flex: 1 1 260px` basis replaces the `flex: 1 1 0` equal-width basis.
Consequence: on desktop the four steps still fill the row, but a step
whose content is short no longer gets padded to an equal share. With
`max-width: 320px` already capping every step, the visual difference is
nil.

### 4. Locker row graphics

`LockersRow.astro` currently renders two images composing one wide shot:

- `lockers-row.png` — 1443x557, 1.3 MB
- `lockers-floor.png` — 1431x262, 582 KB, drawn with `translateY(-10px)`

Together that is 1.9 MB. A CSS `display: none` swap would make phones
download all of it for nothing, so both variants are served as single
`<picture>` sources and only the matching one downloads.

Two composites are generated and committed to `public/images/`:

- `lockers-row-composite.png` — 1443x809. Row at y=0. Floor resized to
  1443x262 at y=547 (the existing 10px overlap). The visible pixels match
  today's two-image composition. The section height changes from 819px to
  809px, because `translateY(-10px)` moves the floor up while its layout
  box still reserves the full 262px, leaving 10px of blank space below.
  The composite removes that blank space.
- `lockers-row-mobile.png` — 618x809. A three-locker crop cut from the
  desktop composite at x=430, width 618. The source row has locker seams
  at x = 17, 224, 430, 637, 842, 1048, 1254 and 1422, so 430 to 1048
  spans exactly three doors with no half-panel at either edge. Cropping
  from the composite rather than from the two sources keeps the floor
  aligned by construction.

`LockersRow.astro` becomes:

```astro
<picture>
    <source media="(max-width: 40rem)" srcset="/images/lockers-row-mobile.png" width="618" height="809" />
    <img src="/images/lockers-row-composite.png" alt="A row of lockers" width="1443" height="809" />
</picture>
```

The alt text stays "A row of lockers". The floor image's alt text, "The
floor of a high school", is descriptive of a decorative element; it is
dropped along with the separate element rather than carried into the
composite's alt, which would describe the same picture twice.

Generation is reproducible via `scripts/build-lockers.mjs`, which uses
`sharp` (already present through Astro; declared in `devDependencies` so
the dependency is explicit). Run with `node scripts/build-lockers.mjs`.
The script reads the two source PNGs and writes both composites. It is
run manually when the source art changes; it is not part of the build.

### 5. Sign-up form

Graffiti stays. The only change is the component's own wrapper width:

```css
.input-group {
    width: 100%;          /* was: width: 1000px */
    max-width: 1000px;
}
```

`.stack-mobile` already supplies the column revert, `--br-m` supplies the
radius, and `body` already carries `theme-lumen`, so the theme tokens are
live. No graffiti overrides are added.

### 6. Two existing bugs fixed in passing

Both are one-line fixes in code this work already touches.

- `house.scss:110` and `house.scss:126` set `display: flexbox`, which is
  not valid CSS and is ignored. `section.banner` and `div.beta-cta` are
  therefore `block`, and their `flex-direction` and `align-items`
  declarations do nothing. The headline centers only via `text-align`
  inside a 60%-wide, left-positioned box. Changing both to `display: flex`
  centers the headline box properly. This is an intentional desktop
  change: the 60%-wide headline shifts from left-of-center to centered.
- The mobile headline needs full width. `section.banner h2` is
  `width: 60%`, which is cramped in a phone-width banner. A media query at
  `40rem` sets `width: 100%` for `section.banner h2`.

### 7. Graffiti decoration at narrow widths

`.graffiti` is absolutely positioned at `top: 50px; right: 100px` with
`transform: scale(0.5)`. Its image is 585px wide, so it renders 292.5px
wide. At a 390px viewport `main` is 334px wide and its right edge sits at
362px, so the graffiti's right edge lands at 262px and its left edge at
-30.5px: it hangs off the left of the viewport. At 320px the left edge is
at -100.5px. It does not extend `scrollWidth`, because the overflow is to
the left, but it is cut off.

At `40rem` and below, `.graffiti` moves into normal flow and becomes a
closing mark rather than a corner overlay:

```scss
.graffiti {
    position: static;
    transform: none;
    max-width: 240px;
    margin: 2rem auto;
}
```

It is already the last element inside `main`, so static positioning places
it after the mission section, centered. This is a deliberate mobile design
change: the slogan reads as a closing statement rather than a badge in the
corner.

### 8. Known issue left alone

`index.astro:87` contains `<ing src="/images/sticker-device-passphrase-linked.png"/>`:
a typo for `<img>`, pointing at a file that does not exist (the file is
`sticker-passphrase-linked.png`). That sticker does not render. It is
unrelated to responsiveness and is not fixed here. Recorded so it is not
lost.

## Files touched

| file | change |
| --- | --- |
| `src/styles/house.scss` | fluid `site-border` and `main`, guide flex basis, `display: flex` fixes, mobile `h2` width, mobile graffiti |
| `src/components/LockersRow.astro` | two `<img>` to one `<picture>` |
| `src/components/SignUp.astro` | `.input-group` width 100% with max-width 1000px |
| `scripts/build-lockers.mjs` | new; generates both composites |
| `package.json` | add `sharp` to `devDependencies` |
| `public/images/lockers-row-composite.png` | new generated asset |
| `public/images/lockers-row-mobile.png` | new generated asset |

## Verification

Not "looks right" — measured. Using `agent-browser` against the dev server:

1. Viewport sweep at 320, 390, 768, 1024, 1442. At each width assert
   `document.documentElement.scrollWidth === window.innerWidth`.
2. At each width, collect `.guide-step` `getBoundingClientRect().top`
   values. Assert the count of distinct values is 4 at 1442 (four
   columns), 3 at 1024 (three columns), 2 at 768 (two columns), and 1 at
   390 and 320 (one column).
3. At 390 assert `.input-group` computed `flex-direction` is `column` and
   its width is less than the viewport width.
4. At 390 assert the loaded locker source is the mobile composite: read
   `document.querySelector('.lockers-row img').currentSrc`.
5. At 1442 assert the desktop composite is loaded and that the rendered
   height is within 2px of `width * 809 / 1443`, confirming the composite
   keeps its intrinsic ratio. At a 1436px row width that is 805px.
6. At 390 and 320 assert `.graffiti`'s left edge is at or below 0, so the
   decoration is not cut off.
7. Screenshot each width for a visual check.

## Risks

- The composites are derived assets. If the source art changes and the
  script is not re-run, the page shows stale art. The script is the
  mitigation; the header comment in `LockersRow.astro` names it.
- `main` sets `background-attachment: fixed`, which can be expensive to
  repaint on iOS during scroll. Not addressed here; noted as a possible
  follow-up.
- The mobile composite is a PNG of a photographic image and will be
  large, perhaps 600-800 KB. Serving WebP or AVIF would cut that
  substantially. Out of scope; noted as a follow-up.
