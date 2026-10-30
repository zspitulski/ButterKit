# Whip design

Whip is an open-source tool for making short kinetic-text videos in the browser: text, shapes and hand-drawn marks that animate across a series of clips. It runs entirely on your computer. There's no account, no server and no upload.

This document is the design for version 1. Nothing is built yet.

## Goals

- Go from a template to a finished video in a few minutes.
- Keep the editor simple: templates on the left, the canvas in the middle, settings on the right and a timeline at the bottom. Animation comes from presets with a few settings, not keyframes.
- Stay small and fast, including on slow computers.
- Export MP4, GIF, PNG and transparent PNG sequences without leaving the browser.
- Keep work in the browser, in `.whip` files and in share links.
- Use a documented file format that people and AI agents can both write.

## Not in version 1

- Images, video or app screenshots inside a story.
- Audio and music.
- Keyframe editing.
- Accounts, cloud storage or any server-side code.
- Canvas sizes other than the four presets.
- Line icons, such as device outlines.
- A community gallery.

## Browser support

| Task | Browsers |
|---|---|
| Editing | Current Chrome, Edge, Firefox and Safari on a computer |
| MP4 export | Chrome and Edge 94+, Firefox 130+ on desktop, Safari 16.4+ |
| GIF and PNG export | Everywhere the editor runs |
| Share links on phones | A player view that plays the story, with an MP4 download where the phone can encode video |

## Architecture

### How frames are drawn

Whip splits the work in two:

1. **The browser lays out the text.** Each text layer is rendered into a hidden HTML element with the real fonts, so the browser handles line breaks, letter spacing, kerning, emoji and right-to-left text. Whip then reads where every letter, word and line landed, using `Range.getClientRects()`.
2. **Whip paints every frame.** One function, `drawFrame(ctx, story, t)`, draws the frame at time `t` onto a canvas with the 2D canvas API. Letters are drawn with `fillText` in the same fonts, so they're never converted to outlines. The live preview and every export call this same function.

Because export uses the same drawing code as the preview, an export matches the preview pixel for pixel.

Two other approaches were considered and rejected:

- **Capturing live web pages frame by frame.** A web page can't take a screenshot of itself. The workarounds are redrawing the page as an SVG image for every frame (slow, and results vary by browser), screen recording (asks permission each time, runs in real time and drops frames on slow machines), or rendering on a server with headless Chrome (needs a server or a local install).
- **Drawing with the GPU (WebGL).** Real blur and glow in every browser, but it needs a large library or a lot of custom graphics code, special font textures to keep large text sharp, and it falls back to slow software rendering on older graphics hardware.

### Parts

| Folder in `src/` | Job |
|---|---|
| `story/` | The document model: clips, layers, text pieces, theme and animations. Validation, repair, defaults and upgrades between format versions. |
| `typeset/` | Lays out text in the hidden HTML area and records letter, word and line boxes. Runs only when text, styles or fonts change, and caches its results. Precomputes the in-between layouts for "Stay centered as it grows". |
| `motion/` | Easing curves, presets, stagger, morph matching and transitions. Pure functions: a layer and a time go in, and each letter's state comes out (opacity, offset, scale, rotation, blur and how much is revealed). |
| `paint/` | `drawFrame`: backgrounds, shapes, marks, letters and effects, including Whip's own blur for Safari. |
| `export/` | The MP4, GIF, PNG and PNG sequence exporters. Loaded the first time someone exports. |
| `save/` | Autosave, the Recent list, `.whip` files and share links. |
| `ui/` | The Preact editor. |

### Data flow

- **Edit:** the editor updates the story as an undoable change, the typesetter re-measures the layers that changed, and the painter redraws the current frame.
- **Play:** on each screen refresh, the painter draws the frame for the new time.
- **Export:** for each frame, the painter draws onto an off-screen canvas and the exporter encodes it.

Export runs on the page's main thread in short slices, with a progress bar and Cancel, because the typesetter needs the page's DOM and fonts. GIF color reduction runs in a Web Worker. Moving the painter into a worker is possible later if exports feel slow.

### Dependencies

| Package | License | Used for |
|---|---|---|
| Preact and @preact/signals | MIT | The editor interface |
| Mediabunny | MPL-2.0 | Writing MP4 and WebM files |
| gifenc | MIT | GIF encoding |
| fflate | MIT | Zip files for PNG sequences |
| Lucide, only the icons used | ISC | Interface icons |

Development only: TypeScript, Vite, Vitest and Playwright.

The editor stays under about 80 KB compressed, not counting fonts. Exporters and fonts load only when needed.

Whip doesn't use GSAP. Its license doesn't allow use in tools for building animations without code.

## Interface

### Layout

- **Top bar:** the Whip logo, "by ButterKit" (opens About), the story name and its menu, size (16:9, 9:16, 1:1, 4:5), undo and redo, Share and Export.
- **Templates, on the left:** grouped by look, followed by Start blank. Hovering a card plays it, drawn live, so there are no preview videos to download. Picking a template starts a new story, and the previous one stays in Recent.
- **Canvas, in the middle:**
  - Click to select, drag to move, and double-click to edit text in place.
  - Selecting words shows a small toolbar for their font, weight and color.
  - With a word selected, Mark adds an underline, circle, check, caret, arrow, burst or swoosh, and Note adds a handwritten side note with a caret. Marks and notes attach to the word and follow it when the text changes or moves.
  - An add bar above the canvas has Text, Shape, Mark and Note.
- **Inspector, on the right:** one scrolling panel that follows the selection.
  - Nothing selected: the story theme, with font slots (main, accent, note), colors and Feel. Feel (Smooth, Snappy or Bouncy) retimes every animation that follows it.
  - Clip: duration, background and the transition to the next clip.
  - Text: type settings, "Stay centered as it grows", and the in and out animations. Preset chips preview on hover, with each preset's settings below.
  - Shape, mark or note: color, stroke, tilt and draw speed.
- **Timeline, at the bottom:**
  - The story strip shows every clip as a block sized by its duration. Drag to reorder or resize, and click the marker between two clips to change the transition. The + button adds a clip that copies the current clip's look, and its menu includes Paste your story.
  - Under the strip, each layer of the selected clip has a bar. Drag a bar to change when that layer starts.
  - Play, scrub and a timecode.

### Paste your story

Paste lines of text and each line becomes a clip in the current look. It's a one-time shortcut. After that, clips are edited directly.

### Keyboard

| Key | Action |
|---|---|
| Space | Play or pause |
| Left and right arrows | Step one frame |
| Cmd-Z, Shift-Cmd-Z | Undo, redo |
| Cmd-D | Duplicate |
| Return | Edit the selected text |
| Esc | Stop editing |
| Cmd-E | Export |
| Cmd-S, Cmd-O | Save, open a file |

Windows and Linux use Ctrl in place of Cmd.

### Phones

Share links open in a player view with an "Edit on a computer" note and, where the phone can encode video, a Download MP4 button.

### Visual style

The interface is quiet and compact, in the spirit of Figma, Sketch and Linear, so the canvas is the only colorful thing on screen.

- Light and dark modes follow the system, with a Light, Dark or System choice in the menu.
- Dark mode uses panels around #2C2C2C on a #1E1E1E background behind the canvas. Light mode uses white panels on light gray.
- Hairline dividers separate sections. Shadows appear only under the video frame and menus.
- Interface text uses the system font (SF Pro on macOS, Segoe UI on Windows) at 11 to 13 pt. Story fonts are separate.
- Inspector sections have a header with one action on the right (+, preview or a menu), followed by compact filled fields. Number fields can be dragged sideways to change their value.
- Segmented controls show the selected option as a raised pill. Icons are Lucide outlines at 16 px.
- There's one accent color: blue #0D99FF, for selection handles, focus rings and switches.
- Export is the only primary button, drawn in ink: black in light mode, white in dark mode. Butter yellow #FFD149 appears only in the logo and in the export progress and finished state.
- Interface animations last 120 to 180 ms and turn off when the system asks for reduced motion.
- Interface text uses sentence case, periods and commas, and no em dashes.

### Links to ButterKit

Whip is made by ButterKit. "by ButterKit" in the top bar opens an About panel with a link to butterkit.app, and a small dismissible card after an export links there too. Exports never carry a watermark.

## Story format

A story is a `.whip` file containing UTF-8 JSON:

```json
{
  "whip": 1,
  "name": "Notes, sorted.",
  "size": "16:9",
  "fps": 60,
  "theme": {
    "fonts": { "main": "inter-display", "accent": "permanent-marker", "note": "permanent-marker" },
    "colors": { "background": "#0B0B0B", "text": "#FFFFFF", "accent": "#FFD149" },
    "feel": "smooth"
  },
  "clips": [
    {
      "duration": 3,
      "transition": { "type": "morph", "match": "words", "duration": 0.6 },
      "layers": [
        { "id": "line", "type": "text", "size": 96,
          "text": ["Your notes, ", { "text": "sorted.", "style": "accent" }],
          "in": { "preset": "rise", "by": "letter", "stagger": 0.03 } },
        { "type": "mark", "mark": "underline", "on": { "layer": "line", "word": "sorted." }, "start": 1.0 },
        { "type": "note", "text": "automatically", "on": { "layer": "line", "word": "sorted." }, "start": 1.4 }
      ]
    },
    {
      "duration": 2.5,
      "layers": [
        { "type": "text", "size": 96, "text": ["Your tasks, ", { "text": "sorted.", "style": "accent" }] }
      ]
    }
  ]
}
```

### Units

- Positions (`at`) and text box widths (`width`) are fractions of the frame, from 0 to 1. Text defaults to `"at": [0.5, 0.5]` and `"width": 0.8`.
- Font sizes, shape sizes and stroke widths are in units. The frame's short side is 1080 units in all four sizes, so a size of 96 is 96 pixels in a 1x export.

| Size | Frame in units, and in pixels at 1x |
|---|---|
| 16:9 | 1920 × 1080 |
| 9:16 | 1080 × 1920 |
| 1:1 | 1080 × 1080 |
| 4:5 | 1080 × 1350 |

- Times are in seconds. `fps` is 30 or 60, with 60 as the default.

### Theme

`theme` holds font slots (`main`, `accent`, `note`), colors (`background`, `text`, `accent` and any others), named styles, and `feel` (`smooth`, `snappy` or `bouncy`).

Any color or font in the story can name a theme slot, like `"accent"`, or give an exact value, like `"#FFD149"` or a font ID. Values that name a slot follow the theme when it changes. The built-in `accent` style means the accent font and the accent color.

### Text

`text` is a string, or a list of pieces. Plain strings use the layer's style. Objects can set `style`, `font`, `weight` or `color`:

```json
"text": ["Your notes, ", { "text": "sorted.", "style": "accent" }]
```

### Marks and notes

Marks and notes are layers that attach to a word: `"on": { "layer": "line", "word": "sorted." }`. Add `"occurrence": 2` when the word appears more than once. The editor updates the reference when the word is edited. If the word disappears, the mark keeps its last position and Whip shows a warning. Without `on`, marks and notes are placed freely with `at`.

Marks animate in with the `draw` preset and notes with the `write` preset, set through the same `in` field as text.

### Animation fields

- `start`: when the layer begins, in seconds from the start of its clip.
- `in` and `out`: `{ preset, duration, by, stagger, order, easing, direction, amount }`, all optional, plus settings specific to a preset, such as Typing's `speed`, `rhythm`, `cursor` and `letters`.
- `easing` defaults to `"feel"`, which follows the story's Feel.
- `transition` sits on the clip it leaves: `{ type, duration, match }`.

### IDs

IDs are optional. Whip assigns IDs to clips and layers when it opens a file. A layer needs an ID only when something refers to it, like `"line"` above.

### Compatibility rules

- New fields are always optional and have defaults.
- Whip keeps fields it doesn't recognize and writes them back when saving.
- Only a change that can't follow these rules increases the `whip` version number, and Whip includes an upgrade step for older files when that happens.
- Saving leaves out values that match their defaults and writes keys in a fixed order, so files stay short and diff cleanly in git.

### Repairs on open

Whip repairs what it can instead of refusing a file. An unknown preset becomes the closest match, out-of-range numbers are clamped and missing values get defaults. Whip then lists every change it made, for example: `Clip 2, text 1: unknown preset "zoomy", used "fade".`

### For AI agents

- `docs/format.md` lists every field, its default, and every preset and mark.
- `schema/whip.schema.json` is a JSON Schema for editors and agents.
- `docs/agents.md` is a prompt to paste into an agent, with complete example stories.
- `scripts/link.mjs` turns a story file into a share link: `node scripts/link.mjs story.whip` prints a link that opens the story in Whip. It uses only Node's built-in modules.

## Motion engine

### Time

Every frame is computed from the time alone. The engine keeps no state between frames, so seeking, looping and exporting always produce the same result for the same time.

- A clip's clock starts at its cut. The story's length is the sum of its clip durations.
- A transition is centered on the cut. Half of its duration comes from the end of the outgoing clip and half from the start of the next one.
- A layer's entrance starts at `start`, then the layer holds, then its exit finishes at the end of the clip. With the exit set to None, the layer holds until the transition takes over.

### Easing and Feel

Whip implements its own easing: cubic-bezier curves (the same model CSS uses) and springs.

| Feel | Curve | Timing |
|---|---|---|
| Smooth (default) | Fast start, long gentle settle | As set |
| Snappy | Sharper curve | About 25 percent shorter |
| Bouncy | Spring with a small overshoot | As set |

Exits use the mirrored curve and accelerate away. Any animation can set its own easing instead of following Feel.

### Presets

Each preset is a single function that maps progress (0 to 1) and its settings to the state of a letter, word or line, so adding a preset means adding one file.

Entrances:

- **Fade**
- **Rise:** from below, above, left or right
- **Blur in**
- **Scale**
- **Reveal:** rises from behind an invisible line
- **Wipe**
- **Track in:** letters slide together from wide spacing
- **Typing:** described below

Exits mirror the entrances. Typing's exit is Backspace. Every layer can also use None as its exit.

Settings: duration, the layer's start time, stagger unit (letter, word or line), stagger gap, order (first to last, last to first, from the center or shuffled), easing, direction, and one amount per preset (distance, blur radius or starting scale).

### Typing

- Speed is set in letters per second, from 8 to 60, with 24 as the default. The entrance's length follows the length of the text.
- Rhythm is Steady, or Human, which adds small seeded variations and short pauses after spaces, commas and periods.
- The cursor is off, a bar or a block. It blinks before and after typing, uses the text color, moves to the next line with the text, and can hide when typing ends.
- Letters appear instantly by default, or with a soft 40 ms fade.
- The Backspace exit deletes from the end at the same speed.

### Letters, words and lines

Text is split into letters with `Intl.Segmenter`, so emoji and combined characters stay whole. In scripts where letters join, such as Arabic, letter-level animation falls back to words. Whole words that aren't animated letter by letter are drawn in one call, so ligatures and joined letters stay intact.

### Stay centered as it grows

When this is on, the line is laid out using only the words visible so far. As each new word appears, the earlier words glide to keep the line centered. If the visible line becomes wider than the frame, it scrolls so the newest word stays in view. The typesetter computes each step's layout ahead of time.

### Morph

Morph is a transition between two clips.

- Whip matches words (the default) or letters between the two clips in reading order, using a longest common subsequence, then matches any remaining identical words nearest first. Trailing punctuation doesn't prevent a match: `sorted` and `sorted.` match, and the period fades in.
- Matched words glide to their new position, size and color. Words leaving the outgoing clip fade out during the first half, and new words in the incoming clip fade in during the second half.
- The morph replaces the incoming clip's entrance for the matched layers. Layers that start later keep their own timing.
- Marks and notes move with the word they're attached to. Shapes with the same ID in both clips glide too.
- Colors blend in the OKLab color space, so in-between colors stay clean.

### Other transitions

Crossfade, Push, Blur, Zoom and Cut. These blend the two clips as whole images.

### Marks and notes

- Marks are hand-drawn paths: underline, circle, check, caret, arrow, burst and swoosh. Each comes in a few drawn variants, picked by seed, so repeated marks don't look identical.
- Attached marks size themselves to their word: an underline spans it, a circle surrounds it, a burst radiates from it, and a caret sits in the gap after it.
- Draw-on traces each stroke from start to end. A burst's strokes draw together.
- Notes use the theme's note font, tilted -5 degrees by default, with a caret. Write-on reveals each letter in writing order, with small seeded timing variations.

### Repeatability and speed

- Anything random comes from a seed stored in the story, so every export of the same story is identical.
- Layouts, morph matches and stroke lengths are computed once and cached.
- While playing on a slow computer, the preview drops to a lower resolution, and returns to full resolution when paused. Exports are always full resolution.

## Look

### Fonts

Whip ships 12 fonts. Each is loaded only when a story uses it, as a Latin-only `woff2` file.

| Role | Fonts |
|---|---|
| Main sans | Inter Display, Geist, Manrope, DM Sans, Space Grotesk |
| Serif | Instrument Serif, Fraunces, Playfair Display |
| Mono | JetBrains Mono, Geist Mono |
| Handwriting, for notes and accent words | Permanent Marker, Caveat |

- Permanent Marker is licensed under Apache 2.0. The others use the SIL Open Font License. Their license texts ship with the fonts.
- Uploaded `.ttf`, `.otf`, `.woff` and `.woff2` files are saved in the browser and inside `.whip` files, but not in share links.
- Chinese, Japanese and Korean text uses the computer's own fonts in version 1, so it can look different on another machine. Uploading a font gives exact control.

### Templates

Version 1 ships 8 templates in two looks. Every template works in all four sizes, and tests check each one at each size.

Keynote minimal:

1. **Big idea:** black background, white Inter Display, one line per clip, with words morphing between clips.
2. **Plain words:** light background with Typing, "Stay centered as it grows", a marker accent word, an underline and a note.
3. **Three words:** short, punchy words, one per beat, using Track in and Scale.
4. **Screenshots, done.:** a sample story about ButterKit, in ButterKit's colors.

Soft gradients:

5. **Warm launch:** a cream, pastry and butter gradient with Blur in and glassy pill shapes.
6. **Calm feature:** a blue and lilac gradient with Rise and an Instrument Serif accent word.
7. **Night glow:** a deep indigo gradient with white text, a soft glow and Track in.
8. **Changelog:** a "What's new" list where check marks draw themselves in as each item lands.

The seven neutral templates share one made-up app. Its name is chosen when the templates are written.

### Backgrounds

- Solid colors, plus linear and radial gradients.
- **Soft gradient:** 3 to 5 large color glows that drift slowly along fixed, repeatable paths. Light grain on top prevents banding in MP4s and GIFs.
- Each clip can have its own background or use the theme's. A background change crossfades between clips, or blends its colors during a morph.

### Shapes

- Rectangles, pills, ellipses and lines, with solid or gradient fills and an optional outline.
- The glass style is a light tint with a hairline edge and a soft shadow. It doesn't blur what's behind it. Blurring a soft gradient barely changes it, so the result looks the same at a fraction of the cost.

### Effects

- **Blur:** Chrome, Edge and Firefox use the canvas's built-in blur filter. Safari keeps that filter behind a developer setting, so Whip draws its own there: the element is drawn small and scaled back up smoothly in two or three steps. Tests compare the result against Chrome's.
- **Glow and shadow:** the canvas's built-in shadows, which work in every browser.
- **Grain:** a fixed noise texture at low strength.
- **Color:** hex colors come out exactly in exports.

## Export, saving and sharing

### Export formats

| Format | Made by | Options | Notes |
|---|---|---|---|
| MP4 | The browser's H.264 encoder (WebCodecs), with Mediabunny writing the file | 1x or 2x (2x is 4K at 16:9), 30 or 60 fps | Falls back to WebM (VP9) if H.264 isn't available. Color is tagged as standard HD (BT.709), so QuickTime shows the same colors as the preview. |
| GIF | gifenc, in a Web Worker | 0.5x or 1x, 25 or 50 fps, always loops | 25 and 50 are the frame rates GIF timing can represent exactly. One palette per clip. Ordered dithering, so gradients don't shimmer between frames. Only changed pixels are stored, which keeps text animations small. |
| PNG | The browser | 1x or 2x, optional transparent background | The current frame. |
| PNG sequence | The browser, zipped with fflate | 1x or 2x, optional transparent background | Numbered frames, with the frame rate in the zip's name. |

### Export sheet

- **Settings:** format, size, frame rate, the whole story or only the current clip, transparency (PNG formats only), and an estimated file size. For a large GIF, the sheet suggests the smaller size.
- **While exporting:** a butter-yellow progress bar, a frame count and Cancel.
- **When finished:** a Save button and the ButterKit card. Chrome and Edge show their Save dialog. Safari and Firefox download the file.
- **Without video support:** the sheet names the browsers that can export video. GIF and PNG still work.

### Saving

- **Autosave:** about a second after each change, the story and any uploaded fonts are saved in the browser's IndexedDB.
- **Recent:** the menu under the story name keeps the last 10 stories with thumbnails. Opening a template or a share link starts a new entry instead of replacing the open story. The same menu has New, Open, Save, Duplicate and Remove from Recent. Remove asks first.
- **Files:**
  - Cmd-S saves a `.whip` file, and Cmd-O opens one. Dragging a `.whip` file onto the window also opens it.
  - In Chrome and Edge, after the first save, Cmd-S saves over the same file, like a desktop app.
  - In Safari and Firefox, each save downloads a new copy.
- **Safari:** Safari deletes a website's stored data after 7 days without a visit, so Recent can empty out there. Until a story has been saved as a file, a small "Only saved in this browser" hint next to its name points to Save.

### Share links

- **Making a link:**
  - Whip leaves out values that match defaults, compresses the story (`deflate-raw`), encodes it as base64url, and puts it after the `#`: `butterkit.app/whip#s1=…`. The `s1` names the link format, so the format can change later without breaking old links.
  - Share copies the link and shows "Link copied."
  - Typical links are a few thousand characters. Past about 8,000 characters, Whip suggests sending the file instead.
  - If the story uses an uploaded font, Whip explains that people opening the link will see Inter Display instead, and suggests sending the file.
- **Opening a link:** the story opens as a new Recent entry, and Whip removes the story from the address bar. A refresh then shows the local copy, and edits never change the original link.
- **Privacy:** browsers don't send the part of a URL after `#` to the server, so stories in links never appear in server logs or page-view counts.
- **Safety:** link contents are untrusted.
  - They're only ever read as data, never as page code.
  - Anything that decompresses to more than 1 MB is rejected.
  - Fonts are never accepted from a link.

### link.mjs

`scripts/link.mjs` uses the same link format with Node's built-in `zlib`, so it needs nothing installed. A test checks that its links open in Whip exactly like links made by the editor.

## Hosting and deployment

- Whip builds to static files, served by a Cloudflare Worker with static assets on the route `butterkit.app/whip*`. Setup must confirm the route doesn't conflict with the main site.
- Code and font files have content-hashed names and are cached long term. The page itself is always revalidated, so updates show up right away.
- A content security policy allows only Whip's own files and Cloudflare Web Analytics.
- Cloudflare Web Analytics counts page views. There are no cookies and no events, and stories in share links are never sent.

### Deploy pipeline

- Pull requests run tests only, without secrets.
- The deploy job runs only after a change lands on `main`. It uses a `production` environment that only `main` can use, and every deploy waits for the maintainer's approval.
- The Cloudflare API token is stored as a secret of that environment and can only deploy Workers.
- Workflows never use the `pull_request_target` trigger.
- Third-party actions are pinned to commit SHAs, and dependencies install with `npm ci` from the lockfile.
- Repository settings require approval before workflows run for any outside contributor, and a rule on `main` blocks force pushes and deletion.

### Same origin as butterkit.app

Whip runs on the same origin as butterkit.app, so Whip's code could read what butterkit.app stores in the browser. butterkit.app has no logins today. If that changes, Whip should move to its own subdomain.

## Repository layout

```
tools/whip/
  README.md               what Whip is, a demo made with Whip, how to run and contribute
  CHANGELOG.md
  index.html
  package.json
  wrangler.jsonc
  src/                    story, typeset, motion, paint, export, save, ui
  templates/              the 8 .whip templates
  fonts/                  the 12 fonts and their licenses
  docs/                   design.md, format.md, agents.md
  schema/whip.schema.json
  scripts/link.mjs
  tests/                  unit tests, browser tests, golden frames, frozen fixtures
  THIRD_PARTY_NOTICES.md  fonts and libraries with their licenses
```

The workflow lives in `.github/workflows/whip.yml` at the repository root.

Whip's own code is covered by the repository's MIT license. `THIRD_PARTY_NOTICES.md` exists because the fonts' licenses and Mediabunny's license require one. The About panel links to it.

## Testing

- **Unit tests (Vitest)** cover the parts that are pure math or data:
  - Easing, presets and stagger order.
  - Morph matching, including letter matching and punctuation.
  - The in-between layouts for "Stay centered as it grows".
  - Opening, repairing and saving story files, including leaving out defaults.
  - Links made by the editor and by `link.mjs`.
  - GIF palettes and dithering.
- **Frozen fixtures:** real `.whip` files from each format version are committed. They must keep opening and drawing the same frames, and they're never edited to make a test pass.
- **Golden frames (Playwright):**
  - Every template is drawn in every size, at fixed moments, in Chromium, WebKit and Firefox, and compared to approved snapshots.
  - Each engine keeps its own snapshots, because text edges differ slightly between engines.
  - The same tests check that Safari's blur stays close to Chrome's.
  - The typesetter is tested here, because it needs a real browser.
- **Export checks:** a 2-second MP4, a GIF and a PNG sequence are exported in a real browser. A test reads the files back and checks their duration, frame count, size and format.
- **Size check:** the build fails if the editor grows past about 80 KB compressed.
- **Before each release:** a manual check in Safari and Firefox on a Mac, mainly for how the blur and exports look.

## Contributing

- **Presets:** one file in `src/motion/presets/`, plus golden frames.
- **Templates:** a `.whip` file in `templates/`, plus golden frames for each size.
- **Marks:** a set of hand-drawn paths in `src/paint/marks/`.

The maintainer reviews and merges every change and approves every deploy.

## Versioning

- butterkit.app/whip shows an "Early preview" label until version 1.0.0.
- Version 1.0.0 requires all 8 templates to be finished and checked in all four sizes.
- Whip keeps its own changelog in `tools/whip/CHANGELOG.md`.

## Decisions

| Decision | Reason |
|---|---|
| The browser lays out text and Whip paints frames on a canvas | Exports match the preview exactly, everything runs in the browser, and the browser handles hard typography like line breaks, emoji and right-to-left text. |
| No GSAP | Its license doesn't allow use in tools for building animations without code. |
| Presets with settings, not keyframes | Faster to learn and harder to make look bad. |
| Preact with signals | A small, React-style editor, where playback updates only the canvas and the playhead. |
| Hosted at butterkit.app/whip | Static files on ButterKit's existing Cloudflare setup, with nothing else to run. |
| Page views only for analytics | No cookies and no event tracking. |
| A JSON file format with forgiving repairs | Easy to write by hand or with AI agents. |
| Every deploy needs the maintainer's approval | The repository is public, and the deploy token is the one secret worth protecting. |

## Later

- Images, video and app screenshots as layers.
- Audio and music.
- Line icons, such as device outlines.
- A community gallery that people add to with pull requests.
- Moving the painter into a Web Worker, if exports need to be faster.
- Custom canvas sizes.
