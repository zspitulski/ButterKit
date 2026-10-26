# The .butterkit document format

A `.butterkit` document is a folder that macOS shows as a single file. Inside is one JSON file that describes the whole design, plus a folder holding every image the design uses. This guide explains that layout so you can read Git diffs, write scripts that inspect your documents, and see for yourself that your work is never locked inside the app. It describes the file, not how ButterKit draws it.

## Contents

- [Package layout](#package-layout)
- [Conventions](#conventions)
- [Inside Document.json](#inside-documentjson)
- [How assets are referenced](#how-assets-are-referenced)
- [Compatibility and versioning](#compatibility-and-versioning)
- [Working with Git](#working-with-git)
- [Reading a document with a script](#reading-a-document-with-a-script)
- [A real example](#a-real-example)
- [Sample document](#sample-document)

## Package layout

```text
My App.butterkit/
├── Document.json
├── Assets/
│   ├── CF2E90DE-8164-4235-8A36-055C74B6354E.jpg
│   ├── 107943FE-4595-41A9-BD1D-258E6876A690.png
│   └── ...
└── QuickLook/
    ├── Thumbnail.png
    └── Preview.pdf
```

| Path | What it is |
| --- | --- |
| `Document.json` | The whole design: artboards, devices, text, overlay images, localizations and App Store text. Always present. |
| `Assets/` | Every image the design uses: screenshots, backgrounds, overlay images and callout crops. A flat folder with no subfolders. Always written, and may be empty. |
| `QuickLook/Thumbnail.png` | The icon Finder shows for the document: up to three base-language artboards fanned out. Optional. |
| `QuickLook/Preview.pdf` | What you see when you press Space in Finder: a cover page, then one page for each of the first 10 base-language artboards. Optional. |

A few things worth knowing:

- The package type is `app.butterkit.document`, which conforms to `com.apple.package`. In Finder, choose **Show Package Contents** to look inside. In Terminal it is an ordinary folder.
- Because it is a folder, zip it before you email or upload it.
- The QuickLook files are previews only. ButterKit doesn't need them to open a document, and it creates them again in the background after you edit.
- Device 3D models and fonts are not stored in the package. Documents refer to them by name and the app supplies them.
- ButterKit writes the package fresh on every save. Files it does not know about, such as a note you drop inside, are not kept.

## Conventions

These apply everywhere in `Document.json`.

- **Encoding.** UTF-8 JSON. ButterKit writes it compact, on a single line. Forward slashes inside strings are escaped as `\/`, which any JSON parser handles.
- **Key order.** Not fixed. The order of keys inside an object can change from one app launch to the next even when nothing else changed.
- **Missing values.** Optional values that are not set are left out, not written as `null`.
- **IDs.** UUID strings in uppercase, such as `D352A431-6073-4B1F-94F0-3CCCDCF52860`.
- **Colors.** sRGB hex strings with alpha last: `#RRGGBBAA`, for example `#676767FF`.
- **Vectors.** Arrays of numbers: `[x, y]` or `[x, y, z]`.
- **Units.** Artboard sizes and positions are in meters (see [Sizes and presets](#sizes-and-presets)). Device rotations are in radians. Values ending in `Pct`, plus a text block's `paddingTop`, `paddingSides`, `paddingLeft` and `paddingRight`, are percentages of the artboard.
- **Enumerations.** Plain strings, such as `"clay"` or `"perspective"`.

## Inside Document.json

### Top level

| Field | Type | Meaning |
| --- | --- | --- |
| `schemaVersion` | integer | Always `1` so far. ButterKit refuses to open a file with any other value. |
| `artboards` | array | Every artboard in the document, base and localized, in no particular order. |
| `baseLanguageCode` | string | Optional. The language the design is written in, as an App Store locale code such as `en-US`. When missing, ButterKit uses the Mac's language. |
| `metadata` | object | Optional. App Store text for each language. See [App Store metadata](#app-store-metadata). |
| `pixelsPerMeter` | number | Optional, written by newer versions. The pixel density behind every artboard `size`. Currently `800`. |

Other top-level keys hold per-document app settings, such as translation preferences. They are not covered here. Leave them as they are.

### Artboards

Every screenshot, in every size and every language, is one artboard. A **base** artboard is the design in the base language. A **localization** is a separate artboard that points back to its base (see [Localizations](#localizations)).

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable ID of the artboard. |
| `name` | string | The name shown in the sidebar. A localization repeats its base artboard's name. |
| `sizePresetID` | string | Optional. The size preset, such as `app_store_iphone`. Missing means a custom size. See [Sizes and presets](#sizes-and-presets). |
| `assetPurpose` | string | Optional. `screenshot`, `header`, `searchResults` or `universal` (shared Header and Search Results artwork). When missing, ButterKit works it out from the preset. |
| `size` | [number, number] | Width and height in meters. |
| `sequenceIndex` | integer | Optional. The artboard's place in its screenshot set. Sort by this, not by array order. The numbers are in order but are not always consecutive or starting at 1. A localization shares its base artboard's number. |
| `position` | [number, number, number] | Where the artboard sits on ButterKit's canvas, in meters. Used to lay out the canvas. |
| `background` | object | See [Backgrounds](#backgrounds). |
| `shadowStyle` | object | Optional. The drop shadow under the devices. Missing means no shadow. See [Device shadow](#device-shadow). |
| `models` | array | The devices on the artboard. See [Devices](#devices). |
| `textBlocks` | array | See [Text blocks](#text-blocks). |
| `imageBlocks` | array | Overlay images. Very old files leave this out, which means none. See [Image blocks](#image-blocks). |
| `parentID` | UUID | Optional. On a localization, the `id` of its base artboard. |
| `variation` | object | Optional. Present only on localizations: `{ "kind": "language", "code": "fr-fr" }`. Its absence is what makes an artboard a base artboard. |
| `linkTextStyles`, `linkBackground`, `linkImages`, `linkCallouts` | boolean | Optional, localizations only, default `true`. Whether the localization follows its base artboard's text styling, background, overlay images and callouts. |
| `cameraProjection` | string | Optional. `orthographic` (the default when missing) or `perspective`. |
| `perspectiveFOVDeg`, `orthoHeight` | number | Optional. Camera framing for the two projections. |
| `spanDevicesEnabled` | boolean | Optional, default `false`. The **Device Overflow** setting: devices may extend onto neighboring artboards. |

### Sizes and presets

To get an artboard's size in pixels, multiply `size` by `pixelsPerMeter`, or by 800 when that key is missing. For example, `[1.6125, 3.495]` is 1290 by 2796 pixels.

A small number of older files were written at 400 pixels per meter. If an artboard with a `sizePresetID` comes out at exactly twice its preset's size, divide by two. ButterKit makes the same correction when it opens such a file.

| `sizePresetID` | Pixels | Name in the app |
| --- | --- | --- |
| `app_store_iphone_medium` | 1206 x 2622 | iPhone for App Store (Medium) |
| `app_store_iphone_medium_landscape` | 2622 x 1206 | iPhone for App Store (Medium, Landscape) |
| `app_store_iphone` | 1290 x 2796 | iPhone for App Store (Large) |
| `app_store_iphone_landscape` | 2796 x 1290 | iPhone for App Store (Large, Landscape) |
| `app_store_iphone_6_5` | 1242 x 2688 | iPhone for App Store (6.5-inch) |
| `app_store_iphone_6_5_landscape` | 2688 x 1242 | iPhone for App Store (6.5-inch, Landscape) |
| `app_store_iphone_duo` | 2007 x 2853 | iPhone Duo (Open) |
| `app_store_iphone_duo_landscape` | 2853 x 2007 | iPhone Duo (Open, Landscape) |
| `app_store_iphone_duo_closed` | 1398 x 2034 | iPhone Duo (Closed) |
| `app_store_iphone_duo_closed_landscape` | 2034 x 1398 | iPhone Duo (Closed, Landscape) |
| `app_store_ipad` | 2048 x 2732 | iPad for App Store |
| `app_store_ipad_landscape` | 2732 x 2048 | iPad for App Store (Landscape) |
| `app_store_mac` | 2880 x 1800 | Mac for App Store |
| `app_store_apple_watch` | 410 x 502 | Apple Watch for App Store |
| `app_store_apple_tv` | 3840 x 2160 | Apple TV for App Store |
| `app_store_visionos` | 3840 x 2160 | Apple Vision Pro for App Store |
| `app_store_header` | 3840 x 1646 | App Store Header |
| `app_store_search_results` | 3840 x 2560 | App Store Search Results |
| `app_store_creative_universal` | 5244 x 2950 | App Store Shared Header and Search Results |
| `google_play_store` | 1080 x 1920 | Google Play Store |

New presets are added over time. If you meet an ID that is not listed, treat the artboard as a custom size and use `size`.

### Backgrounds

`background` is an object with exactly one key, which says what kind of background it is.

```json
{ "color": { "hex": "#FFFFFFFF" } }
```

```json
{ "linearGradient": { "topHex": "#112233FF", "bottomHex": "#445566FF" } }
```

```json
{ "image": { "ref": { "type": "document", "name": "107943FE-4595-41A9-BD1D-258E6876A690.png" }, "fill": "fill" } }
```

For images, `fill` is `fit`, `fill` or `stretch`. Unknown values are read as `fit`. See [How assets are referenced](#how-assets-are-referenced) for `ref`.

### Device shadow

| Field | Type | Meaning |
| --- | --- | --- |
| `enabled` | boolean | Whether the shadow is on. |
| `angleDeg` | number | The direction the shadow falls, in degrees. 0 is straight down. |
| `distance` | number | How far the shadow is offset, as a fraction of the artboard's height. |
| `softness` | number | How blurred it is, as a fraction of the artboard's height. |
| `opacity` | number | 0 to 1. |
| `colorHex` | string | Shadow color. |

### Devices

Each entry in `models` is one device on the artboard.

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable ID of this device on this artboard. |
| `sourceModelID` | UUID | On a base artboard, the same as `id`. On a localization, the `id` of the matching device on the base artboard. When missing, the device's own `id`. |
| `assetName` | string | Which device, for example `iPhone18ProMax`, `iPadPro129`, `MacbookPro16`, `AppleWatchSeries11`, `Pixel10Pro` or `iPhoneDuo`. New devices are added over time. |
| `instanceLabel` | string | Optional. The name shown in the app, such as `iPhone 18 Pro Max`. |
| `deviceStyle` | string | `realistic`, `clay` or `uiOnly`. |
| `clayColorHex` | string | Body color for the clay style. |
| `realisticFinish` | string | Optional. The color finish for the realistic style, such as `iphone18pro.silver.v1`. |
| `screenImageFilename` | string | Optional. The screenshot on the device's screen, a file name in `Assets/`. Missing means an empty screen. |
| `coverScreenImageFilename` | string | Optional. iPhone Duo only: the screenshot on the cover screen. |
| `rotationEuler` | [number, number, number] | Rotation in radians. |
| `scale` | [number, number, number] | Scale. `[1, 1, 1]` is the default size. |
| `positionOffset` | [number, number, number] | Where the device sits on its artboard, in meters. The axes follow the app's own conventions, so compare values rather than computing positions from them. |
| `hingeAngleDeg` | number | Optional. iPhone Duo hinge angle, from 0 (closed) to 180 (flat). |
| `showsDisplayCutout` | boolean | Optional, default `true`. Whether the screen shows the camera cutout. |
| `uiOnlyOverlayCornerRadiusFactor` | number | Corner rounding for the UI only style. 0 when missing. |
| `callouts` | array | Optional, default empty. Magnified crops of the screenshot, described below. |

#### Callouts

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable ID of the callout. |
| `sourceRect` | [number, number, number, number] | The cropped region of the screenshot as `[x, y, width, height]`, each from 0 to 1. |
| `imageFilename` | string | Optional. The cropped image, a file name in `Assets/`. |
| `screenRole` | string | Optional. `cover` when the crop comes from the iPhone Duo cover screen. Missing means the main screen. |
| `borderStyle` | string | `none`, `solid`, `glow` or `liquidGlass`. |
| `borderColorHex` | string | Border color. |
| `borderWidth`, `cornerRadius`, `magnification`, `scale` | number | The callout's look and size, in the app's own units. |
| `positionOffset` | [number, number] | How far the callout is moved from its source region. |

### Text blocks

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable ID. A localization's copy of a block keeps the base block's `id`. |
| `role` | string | The layer name shown in the app, for example `Title` or `Subtitle`. |
| `index` | integer | Stacking order among the artboard's text blocks. 0 is at the back. |
| `string` | string | The text in the base language. |
| `translatedString` | string | Optional. On a localization, the translated text. The text shown is `translatedString` when present, otherwise `string`. |
| `translationPhrase` | string | Optional. When set, this is translated instead of `string`. |
| `doNotTranslate` | boolean | Optional, default `false`. Automatic translation skips this block. |
| `fontFamily` | string | Font family name. `System Default` means the system font. |
| `weight` | string | `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy` or `black`. |
| `isItalic`, `isUnderlined` | boolean | Style toggles. |
| `areLigaturesEnabled` | boolean | Optional, default `true`. |
| `sizePt` | number | Font size in points. |
| `colorHex` | string | Text color. |
| `alignment` | string | How lines line up inside the block: `leading`, `center` or `trailing`. |
| `horizontalAlignment` | string | Where the block sits across the artboard: `leading`, `center` or `trailing`. |
| `paddingTop` | number | Distance from the top of the artboard, as a percentage of its height. |
| `sidePaddingMode` | string | Optional. `uniform` uses `paddingSides` on both sides. `individual` uses `paddingLeft` and `paddingRight`. When missing, `uniform` if left and right match. |
| `paddingSides` | number | Side padding as a percentage of the artboard's width, 0 to 40. |
| `paddingLeft`, `paddingRight` | number | Optional. Per-side padding in the same units. When missing, `paddingSides`. |
| `lineSpacingMultiple` | number | Optional, default `1`. |
| `scaleToSingleLine` | boolean | Optional, default `false`. The **Fit on 1 Line** setting: the text shrinks until it fits on one line. |
| `textStrokes` | array | Optional. Outlines, each `{ "colorHex", "width" }`. |
| `textShadows` | array | Optional. Shadows, each `{ "colorHex", "radius", "x", "y" }`. |
| `textBackground` | object | Optional. A box behind the text: `{ "colorHex", "hPadding", "vPadding", "cornerRadius" }`. |

You may also see a few internal layout flags, such as `usesTopAnchoredLineHeight`. They are not covered here.

### Image blocks

Overlay images placed on the artboard, such as badges, logos or award laurels.

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | UUID | Stable ID. |
| `role` | string | The name shown in the Images inspector. |
| `index` | integer | Order among the artboard's image blocks, starting at 0. |
| `ref` | object | The image file. See [How assets are referenced](#how-assets-are-referenced). |
| `xPct`, `yPct` | number | The center of the image, as a percentage of the artboard's width and height, measured from the top left. 50 and 50 is the middle. |
| `scalePct` | number | The image's width as a percentage of the artboard's width. |
| `opacity` | number | 0 to 100. |
| `rotationDeg` | number | Optional, default `0`. Clockwise rotation in degrees around the image's center. |

### Localizations

Each language you add creates one extra artboard per base artboard. The localized artboard:

- has its own `id`, a `parentID` pointing at the base artboard, and a `variation` such as `{ "kind": "language", "code": "fr-fr" }`,
- stores a complete copy of its content (background, devices, text and images), so you can read it without looking up the base,
- keeps the base artboard's `name`, `sizePresetID` and `sequenceIndex`,
- reuses the base artboard's text block IDs, with the translation in `translatedString`,
- gives each device its own `id`, with `sourceModelID` pointing at the base device,
- can hold its own screenshots, which is how localized screenshots work.

Language codes are App Store Connect locale codes. Current files write them in lowercase, such as `fr-fr`, `de-de` or `ja`, while `baseLanguageCode` keeps its usual form, such as `en-US`, so compare them without regard to case. Today `kind` is always `language`. Skip any other kind you meet.

An illustrative, trimmed pair (IDs shortened to obvious placeholders):

```json
[
  {
    "id": "AAAAAAAA-0000-4000-8000-000000000001",
    "name": "Intro",
    "sequenceIndex": 1,
    "textBlocks": [
      { "id": "CCCCCCCC-0000-4000-8000-000000000001", "role": "Title", "string": "Hello world" }
    ],
    "models": [
      { "id": "BBBBBBBB-0000-4000-8000-000000000001", "sourceModelID": "BBBBBBBB-0000-4000-8000-000000000001" }
    ]
  },
  {
    "id": "AAAAAAAA-0000-4000-8000-000000000002",
    "parentID": "AAAAAAAA-0000-4000-8000-000000000001",
    "variation": { "kind": "language", "code": "fr-fr" },
    "name": "Intro",
    "sequenceIndex": 1,
    "linkBackground": true,
    "textBlocks": [
      { "id": "CCCCCCCC-0000-4000-8000-000000000001", "role": "Title", "string": "Hello world", "translatedString": "Bonjour le monde" }
    ],
    "models": [
      { "id": "BBBBBBBB-0000-4000-8000-000000000002", "sourceModelID": "BBBBBBBB-0000-4000-8000-000000000001" }
    ]
  }
]
```

### App Store metadata

`metadata` holds the App Store text you edit in ButterKit. Its keys are language codes in the same lowercase form as `variation.code`, plus `__BASE__` for the base language. Each value has three strings:

| Field | Type | Meaning |
| --- | --- | --- |
| `description` | string | The App Store description. |
| `promotionalText` | string | The promotional text. |
| `whatsNew` | string | The release notes for the next version. |

## How assets are referenced

Every image is referenced by a plain file name, with no folder, that lives directly inside `Assets/`.

| Image | Field |
| --- | --- |
| Device screenshot | `models[].screenImageFilename` |
| iPhone Duo cover screenshot | `models[].coverScreenImageFilename` |
| Callout crop | `models[].callouts[].imageFilename` |
| Background image | `background.image.ref` |
| Overlay image | `imageBlocks[].ref` |

Backgrounds and overlay images use a small reference object:

```json
{ "type": "document", "name": "691ECD66-CD22-4EC3-B25E-2C22371FDA3E.png" }
```

- `document` means the file is in `Assets/` under `name`. This is what you will almost always see.
- `bundle` means an image built into the app. `name` identifies it, but the file is not in the package. When ButterKit saves, it copies built-in background images into `Assets/` and switches them to `document`.

Some rules that make assets easy to work with:

- File names are a random UUID plus the original extension, sometimes with a prefix such as `callout-` or `background-`. A name never changes once written. Most files are PNG or JPEG.
- Several references can share one file, for example the same screenshot on a base artboard and its localizations.
- ButterKit saves only the files the JSON references, so `Assets/` never fills up with orphans.
- If a referenced file is missing, the element opens without its image.

**Linked screenshot folders.** When a document is linked to a folder of screenshots, each refresh compares the incoming screenshot with the one already in the document, byte for byte. If nothing changed, the existing file and its name stay. Only screenshots that really changed get a new file, so a refresh with no changes leaves the document untouched.

To list every file a document references (handy for a CI check that nothing is missing):

```sh
jq -r '.artboards[]
  | (.background.image.ref | select(.type == "document") | .name),
    ((.imageBlocks // [])[].ref | select(.type == "document") | .name),
    (.models[] | .screenImageFilename, .coverScreenImageFilename, (.callouts // [])[].imageFilename)
  | strings' "My App.butterkit/Document.json" | sort -u
```

## Compatibility and versioning

**What is promised.** A document saved by any earlier version of ButterKit opens in the current version. Every field added since the first release is optional, and a missing field is read with the default listed in the tables above. ButterKit's own test suite keeps frozen copies of old document JSON and fails if a change would stop them opening or lose any of their artboards, devices, text or images.

**What is not promised.**

- Opening a newer document in an older version of ButterKit. Older versions ignore keys they don't know, so the file usually opens with the newer features missing. A few new values, such as a new device style, can stop an older version from opening the file at all. Saving from the older version drops the newer keys. Update ButterKit before opening files from someone on a newer version.
- A writing API. The format is designed for ButterKit's own reader. Names and meanings can change in ways the app handles safely but a hand-written file would not.

**If you read documents**, make your code tolerant:

- Check that `schemaVersion` is `1`.
- Ignore keys you don't recognize. New ones appear over time.
- Treat a missing optional key as its default.
- Don't depend on key order, or on the order of the `artboards` array. Use `sequenceIndex`.
- Expect new strings in enumerated fields, such as new preset IDs, device names or styles, and fall back gracefully.
- If your tool rewrites a document, carry unknown keys through untouched.

**Please don't hand-edit.** Reading is safe. Writing is risky, for three reasons:

- ButterKit rebuilds `Document.json` from what it understands on every save, so keys you add are dropped.
- Some fields are strict. An unrecognized `deviceStyle` stops the whole document from opening, and one malformed callout drops every callout on that device without an error.
- Values depend on each other in ways this guide doesn't describe, such as localizations mirroring their base artboard.

To change documents from a script or an AI agent, use ButterKit's [MCP server](../mcp), which makes changes through the app. If you must edit by hand, work on a copy, change values rather than structure, and open the result in ButterKit before you commit it.

## Working with Git

### Make diffs readable

Because ButterKit writes `Document.json` on one line, and key order can shift between app launches, a raw diff is one enormous changed line. Teach Git to sort and indent the JSON before comparing it, using [jq](https://jqlang.org) (`brew install jq` if you don't have it).

Add this to `.gitattributes` in your repository:

```gitattributes
**/*.butterkit/Document.json diff=butterkit
**/*.butterkit/QuickLook/** -diff
```

Then run this once in each clone, or add `--global`:

```sh
git config diff.butterkit.textconv "jq -S ."
```

Now `git diff`, `git log -p` and `git show` print one key per line in sorted order, and a save that only reshuffled keys shows no change at all. Web views, such as diffs on GitHub, still show the raw file.

### What a typical diff looks like

IDs never change, so a sorted diff shows only what you actually edited. Editing a headline that also has a French translation looks something like this (illustrative and trimmed). The first hunk is the base text block, the second is its French copy:

```diff
           "sizePt": 60,
-          "string": "Relaxing audio",
+          "string": "Calming audio",
           "weight": "black"
```

```diff
           "sizePt": 60,
-          "string": "Relaxing audio",
-          "translatedString": "Audio relaxant",
+          "string": "Calming audio",
+          "translatedString": "Audio apaisant",
           "weight": "black"
```

Other everyday changes:

- **Moving or rotating a device** changes that device's `positionOffset` or `rotationEuler`.
- **Replacing a screenshot** changes `screenImageFilename`, adds the new file to `Assets/` and removes the old one if nothing else uses it.
- **Adding a language** adds one artboard per base artboard, each with a `parentID` and a `variation`.
- **Rearranging the canvas** changes artboard `position` values. That's canvas layout, and usually safe to skim past.

### What to ignore

- `.DS_Store` files, which Finder sometimes leaves inside packages.
- `QuickLook/`, if you like. ButterKit rewrites these previews after most visual edits, and they are optional. If you ignore them, Finder shows a plain icon on a fresh checkout until the next save.

```gitignore
.DS_Store
**/*.butterkit/QuickLook/
```

### Merging and history

- Git can't merge two people's edits to the same one-line `Document.json`. When both branches changed a document, keep one side's whole package, so the JSON and `Assets/` stay in step, then redo the other change in ButterKit:

  ```sh
  git checkout --theirs -- "Screenshots/My App.butterkit"
  ```

- Every replaced screenshot adds a new image to your history. If that grows large, consider [Git LFS](https://git-lfs.com) for `**/*.butterkit/Assets/**`.
- Before pushing to a public repository, remember that `Assets/` holds screenshots of your app and `metadata` may hold release notes you haven't published yet.

## Reading a document with a script

This Python script lists a document's languages and its base artboards in screenshot order, with pixel sizes and text. It uses only the standard library, and it's ready to run as [`tools/list_boards.py`](tools/list_boards.py) (MIT licensed).

```python
import json
import sys
from pathlib import Path

SUPPORTED_VERSIONS = {1}

package = Path(sys.argv[1])
doc = json.loads((package / "Document.json").read_text(encoding="utf-8"))
if doc.get("schemaVersion") not in SUPPORTED_VERSIONS:
    sys.exit("Unsupported schemaVersion")

ppm = doc.get("pixelsPerMeter", 800)
boards = doc["artboards"]
languages = sorted({
    b["variation"]["code"] for b in boards
    if (b.get("variation") or {}).get("kind") == "language"
})
print("Base language:", doc.get("baseLanguageCode"))
print("Localizations:", ", ".join(languages) or "none")

base = [b for b in boards if not b.get("variation")]
for b in sorted(base, key=lambda b: (b.get("sizePresetID") or "custom", b.get("sequenceIndex") or 0)):
    width, height = (round(v * ppm) for v in b["size"])
    texts = [t["string"] for t in sorted(b["textBlocks"], key=lambda t: t["index"])]
    print(f'{b.get("sizePresetID") or "custom"} #{b.get("sequenceIndex")} {width}x{height} {b["name"]}: {" / ".join(texts)}')
```

Run against the Ethereal sample, it starts like this:

```text
$ python3 tools/list_boards.py samples/Ethereal.butterkit
Base language: en-US
Localizations: none
app_store_iphone #1 1290x2796 Introduction: Easy peasy / Meditation for the rest of us
app_store_iphone #2 1290x2796 Bottom: Lessons / Included for free
app_store_iphone #3 1290x2796 Top: Relaxing audio / Find calm anywhere
```

## A real example

One artboard from the Ethereal template, trimmed. The other 17 artboards and the subtitle block are removed, and keys are reordered for reading.

```json
{
  "schemaVersion": 1,
  "baseLanguageCode": "en-US",
  "metadata": {},
  "artboards": [
    {
      "id": "D352A431-6073-4B1F-94F0-3CCCDCF52860",
      "name": "Top",
      "sizePresetID": "app_store_iphone",
      "sequenceIndex": 3,
      "size": [1.6125, 3.495],
      "position": [4.19125, 0, 0],
      "background": {
        "image": {
          "fill": "fill",
          "ref": { "type": "document", "name": "107943FE-4595-41A9-BD1D-258E6876A690.png" }
        }
      },
      "cameraProjection": "perspective",
      "perspectiveFOVDeg": 35,
      "orthoHeight": 0.18917927,
      "spanDevicesEnabled": false,
      "models": [
        {
          "id": "12ED0949-C35A-4906-B4A2-55E24AF1D1B3",
          "sourceModelID": "12ED0949-C35A-4906-B4A2-55E24AF1D1B3",
          "assetName": "iPhone18ProMax",
          "instanceLabel": "iPhone 18 Pro Max",
          "deviceStyle": "clay",
          "clayColorHex": "#666666FF",
          "rotationEuler": [0, 0, 0],
          "scale": [1, 1, 1],
          "positionOffset": [0, -0.027, 0],
          "screenImageFilename": "CF2E90DE-8164-4235-8A36-055C74B6354E.jpg",
          "uiOnlyOverlayCornerRadiusFactor": 0
        }
      ],
      "textBlocks": [
        {
          "id": "B96F561E-F749-4034-B20F-5B5BB93D84BC",
          "role": "Title",
          "index": 0,
          "string": "Relaxing audio",
          "fontFamily": "Fraunces",
          "weight": "black",
          "isItalic": false,
          "isUnderlined": false,
          "areLigaturesEnabled": true,
          "sizePt": 60,
          "colorHex": "#676767FF",
          "alignment": "center",
          "horizontalAlignment": "center",
          "paddingTop": 6.287003403529525,
          "sidePaddingMode": "uniform",
          "paddingSides": 15.626064241486066,
          "paddingLeft": 15.626064241486066,
          "paddingRight": 15.626064241486066,
          "lineSpacingMultiple": 1,
          "scaleToSingleLine": true
        }
      ],
      "imageBlocks": []
    }
  ]
}
```

Its size works out to 1290 by 2796 pixels, the `app_store_iphone` preset, and both image names are files in `samples/Ethereal.butterkit/Assets/`.

## Sample document

[`samples/Ethereal.butterkit`](samples/Ethereal.butterkit) is the Ethereal template, a complete, real document you can open in a text editor or run scripts against. Every other free template is at [butterkit.app/templates](https://butterkit.app/templates?utm_source=github).

Two things to keep in mind. The sample is indented to make it easier to read, while a file the app saves is compact. And it contains no localizations, callouts or device shadows, so those fields only appear in documents where you use them.

The sample isn't covered by this guide's CC BY 4.0 license. See [LICENSE.md](LICENSE.md).

---

This guide is licensed under [CC BY 4.0](LICENSE.md).
