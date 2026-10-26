# Changelog

Every ButterKit release, newest first. This file mirrors [butterkit.app/changelog](https://butterkit.app/changelog?utm_source=github), where each release has full notes, images and video.

## 3.1.01

**Apply to All Localizations, starter text on blank artboards, and fixes**  
<sub>October 18, 2026</sub>

- Apply to All Localizations: changed the source screenshot? One click in the Screen Image box now puts it on every localized version of that device, and you can undo it. Thanks to Andrew M and folks on reddit for helping on this.
- Blank artboards start with a title and subtitle: new boards begin with placeholder text sized for each format.
- Improved Apple Watch templates: the watch is now sized better by default
- The Upload sheet's App, Device and Version menus now show a loading state while App Store Connect API responds.
- The custom color hex field in the Backgrounds palette keeps a fixed width, selects its value on click and ignores overlong input.
- Fixes an issue where a project created with Preview Quality set to Regular opened at twice its size once the quality was High, and its exports were rejected by App Store Connect. Affected projects are converted automatically when opened, and exports now come out at document size at either quality.
- Fixes a bug where "Copy Text Block to.." left the block's translations behind (thanks Habitoti)
- Fixes a bug where text in a language set to Manual translation kept showing the original source text after the source was edited.
- Fixes an issue where Add Artboard from the canvas menu added the template's iPhone instead of the device for the selected size.
- Fixes a format alert when capturing an Apple Watch screenshot with the Capture Tool.

[All release notes](https://butterkit.app/changelog?utm_source=github)

## 3.0.06

**Meet ButterKit 3: New sizes, new artwork, smoother everything**  
<sub>October 9, 2026</sub>

Migrate to the new App Store sizes in one click, design the new Header and Search Results artwork, and manage your metadata without leaving ButterKit.

[Full release notes](https://butterkit.app/changelog/v3-0-new-app-store-sizes/?utm_source=github)

## 2.5

**New iPhone Duo and iPhone 18 Pro Max, camera notch controls, and Product Page Headers**  
<sub>September 25, 2026</sub>

ButterKit 2.5 adds editable 3D iPhone Duo and iPhone 18 Pro Max models, updated realistic device materials, a camera notch toggle, support for App Store Connect Product Page Headers, and improvements to the Add Artboard flow.

[Full release notes](https://butterkit.app/changelog/v2-5-new-devices/?utm_source=github)

## 2.3

**Introducing Drop Shadows: more depth and realism for your devices**  
<sub>September 10, 2026</sub>

ButterKit 2.3 adds customizable 3D drop shadows to your devices, a more reliable MCP for AI agents, wider emoji support and more flexible uploads for App Store Connect, a show/hide button for the Inspector, and preparation for macOS 27.

[Full release notes](https://butterkit.app/changelog/v2-3-drop-shadows/?utm_source=github)

## 2.2

**The new ButterKit icon and brand**  
<sub>July 29, 2026</sub>

ButterKit has changed a lot since it launched! New features, hundreds of improvements, and now macOS 27 support. It was time for a new look to match: a new logo, wordmark, and color palette built around one idea: simple ingredients, iterated on repeatedly, produce something that rises.

[Full release notes](https://butterkit.app/changelog/v2-2-new-brand/?utm_source=github)

## 2.0.08

**A more buttery ButterKit: a rebuilt SwiftUI canvas and image rotation**  
<sub>July 5, 2026</sub>

ButterKit 2 rebuilds the canvas on SwiftUI for a noticeably faster, smoother, more buttery experience. Plus rotate any image, logo, or badge, and much faster App Store Connect uploads.

[Full release notes](https://butterkit.app/changelog/v2-0-08-image-rotation/?utm_source=github)

## 1.9

**Introducing Callouts: a new way to highlight your features and UI**  
<sub>May 7, 2026</sub>

Callouts let you highlight features and UI in 3D space alongside your devices. Plus performance boosts and refreshed onboarding.

[Full release notes](https://butterkit.app/changelog/v1-9-callouts/?utm_source=github)

## 1.8.21

**Your translations can now take direction**  
<sub>April 23, 2026</sub>

Add translation instructions in Project Settings so AI models know your tone, capitalization rules, and what not to translate.

[Full release notes](https://butterkit.app/changelog/v1-8-21-custom-translation-instructions/?utm_source=github)

## 1.8.10

**11 new App Store Languages, Apple Vision Pro, and AI Image Placement**  
<sub>April 3, 2026</sub>

ButterKit now supports all 50 App Store Connect languages, adds Apple Vision Pro support, and lets AI agents place images on your artboards.

[Full release notes](https://butterkit.app/changelog/v1-8-10-vision-pro-languages/?utm_source=github)

## 1.8.01

**MCP Support: AI-Powered Screenshot Generation and Localization**  
<sub>March 21, 2026</sub>

ButterKit now speaks MCP (beta). Generate screenshots, localize into 39 languages, and upload to ASC from any AI agent or CI pipeline.

[Full release notes](https://butterkit.app/changelog/v1-8-01-mcp-support/?utm_source=github)

## 1.7.20

**Delta Translation, Preview Navigation, and alignment fixes**  
<sub>February 25, 2026</sub>

Introduces Delta Translation for smarter, incremental re-translation, adds Preview Navigation controls, and fixes Device Overflow alignment issues.

[Full release notes](https://butterkit.app/changelog/v1-7-20-delta-translation/?utm_source=github)

## 1.7.10

**"Do Not Translate" toggle, improved undo, and text refinements**  
<sub>February 16, 2026</sub>

Adds a highly requested 'Do Not Translate' toggle for text blocks, plus improved undo reliability, better cloud translation fallback, and numerous text and layout refinements.

[Full release notes](https://butterkit.app/changelog/v1-7-10-do-not-translate-toggle/?utm_source=github)

## 1.7.01

**Customizable images per localization, new fonts, improved text editing, and more**  
<sub>February 11, 2026</sub>

Images like logos and stickers can now differ per language. Plus new fonts, toast notifications, and text editing improvements.

[Full release notes](https://butterkit.app/changelog/v1-7-01-improved-images-and-fonts/?utm_source=github)

## 1.6.35

**Improved translations, UI, App Store Connect validation, user-added templates and more**  
<sub>January 31, 2026</sub>

Upgraded localization workflow with multi-select, market size data, and better UI. App Store Connect metadata now validates for emojis before upload.

[Full release notes](https://butterkit.app/changelog/v1-6-35-improved-translations/?utm_source=github)

## 1.6.12

**New text tools, Apple Watch 3D model, improved performance, and more butter!**  
<sub>January 22, 2026</sub>

Highly requested "Fit to 1 line" text option, independent left/right padding, 3D Apple Watch Series 11, and smoother performance.

[Full release notes](https://butterkit.app/changelog/v1-6-12-text-tools-apple-watch/?utm_source=github)

## 1.5.03

**UI Improvements and folder-linking bug fixes**  
<sub>January 7, 2026</sub>

Improves metadata, settings, and license management UI. Fixes rendering quality and translation bugs.

[Full release notes](https://butterkit.app/changelog/v1-5-03-ui-improvements/?utm_source=github)

## 1.5.01

**Folder-linking (e.g. Fastlane), additional text controls & more**  
<sub>January 4, 2026</sub>

Screenshot folder-linking support for tools like Fastlane, improved text editing controls, and dozens of UI refinements.

[Full release notes](https://butterkit.app/changelog/v1-5-01-folder-linking/?utm_source=github)

## 1.4.20

**Holiday update with new 3D device, templates & more**  
<sub>December 23, 2025</sub>

Seamless Backgrounds, high resolution Apple Watch 3D model, new templates section, and improved color picking UI.

[Full release notes](https://butterkit.app/changelog/v1-4-20-holiday-update/?utm_source=github)

## 1.4.12

**Performance improvements and bug fixes**  
<sub>December 15, 2025</sub>

Improved UI for localizations, easier source language setting, and critical bug fixes for exporting and translations.

[Full release notes](https://butterkit.app/changelog/v1-4-12-performance-improvements/?utm_source=github)

## 1.4.05

**Introducing Device Overflow**  
<sub>December 7, 2025</sub>

Device Overflow is a new way to quickly create stunning designs with 3D devices that span across multiple artboards, rendered in realtime using Metal.

[Full release notes](https://butterkit.app/changelog/v1-4-05-device-overflow/?utm_source=github)

## 1.3.12

**Text line-height, background image controls, and UX improvements**  
<sub>November 14, 2025</sub>

Text editing now supports line-height and ligature controls. Copy text blocks between artboards and override background styles on variants.

[Full release notes](https://butterkit.app/changelog/v1-3-12-text-line-height/?utm_source=github)

## 1.3.11

**Text shadows, text strokes, UX improvements**  
<sub>November 11, 2025</sub>

New text shadows and text strokes! Plus arrow key adjustments on input fields and quick copy for 3D models between artboards.

[Full release notes](https://butterkit.app/changelog/v1-3-11-text-shadows/?utm_source=github)

## 1.3.07

**The big v1.3 October Update: App Store metadata uploads, new models, bug fixes and more!**  
<sub>October 31, 2025</sub>

ButterKit can now translate and upload App Store Connect metadata directly! Plus support for Gemini, Anthropic, OpenRouter, and a buttery new look.

[Full release notes](https://butterkit.app/changelog/v1-3-07-october-update/?utm_source=github)

## 1.2.32

**Add custom images to artboards**  
<sub>October 21, 2025</sub>

Easily add custom images (logos, graphics, illustrations) to your artboards via the new Images tab in the Inspector.

[Full release notes](https://butterkit.app/changelog/v1-2-32-custom-images/?utm_source=github)

## 1.2.26

**Stability improvements**  
<sub>October 17, 2025</sub>

Fixes for landscape screenshots, export thumbnails, App Store Connect log, and new Spanish localization.

[Full release notes](https://butterkit.app/changelog/v1-2-26-stability-improvements/?utm_source=github)

## 1.2.23

**Improved 3D models, mouse navigation, ASC API fixes**  
<sub>October 14, 2025</sub>

More accurate and photorealistic iPhone and iPad 3D models, improved lighting, and middle mouse button navigation.

[Full release notes](https://butterkit.app/changelog/v1-2-23-improved-3d-models/?utm_source=github)

## 1.2.20

**Customize variant translations**  
<sub>October 10, 2025</sub>

Highly requested: easily adjust translations on variant artboards when a translation is longer than your design allows.

[Full release notes](https://butterkit.app/changelog/v1-2-20-customize-variant-translations/?utm_source=github)

## 1.2.15

**Improved navigation with the trackpad**  
<sub>October 7, 2025</sub>

Pinch-to-zoom and general trackpad navigation is much smoother — more butter added!

[Full release notes](https://butterkit.app/changelog/v1-2-15-trackpad-navigation/?utm_source=github)

## 1.2.12

**Performance/RAM usage improvements, font fix, and German language support**  
<sub>October 6, 2025</sub>

Significant improvements to RAM usage, background CPU usage fixes, and German localization.

[Full release notes](https://butterkit.app/changelog/v1-2-12-performance-german/?utm_source=github)

## 1.2.01

**App Store Connect Uploads**  
<sub>October 1, 2025</sub>

Direct App Store Connect uploads via the ASC API. Upload all of your screenshots directly from ButterKit to App Store Connect.

[Full release notes](https://butterkit.app/changelog/v1-2-01-app-store-connect-uploads/?utm_source=github)

## 1.1.23

**App Store Previews**  
<sub>September 25, 2025</sub>

See how your design and layouts will look on the App Store before you export with the new App Store Preview feature.

[Full release notes](https://butterkit.app/changelog/v1-1-23-app-store-previews/?utm_source=github)

## 1.1.3

**Added support for markdown**  
<sub>September 16, 2025</sub>

Use markdown when editing text to emphasize certain words. Bold and italic renders instantly onto your artboards.

[Full release notes](https://butterkit.app/changelog/v1-1-3-markdown-support/?utm_source=github)

## 1.0.9

**Improved zoom and pan behavior**  
<sub>September 10, 2025</sub>

Smoother, more precise panning on the canvas and new ⌘+ and ⌘- keyboard shortcuts to quickly zoom in and out.

[Full release notes](https://butterkit.app/changelog/v1-0-9-zoom-and-pan/?utm_source=github)

## 1.0.4

**Added OpenAI support (bring-your-own API key)**  
<sub>September 5, 2025</sub>

Connect your own OpenAI API key for translations. Plus reduced panning speed and improved translation language selection UI.

[Full release notes](https://butterkit.app/changelog/v1-0-4-openai-support/?utm_source=github)
