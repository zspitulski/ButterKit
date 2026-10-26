# Agent prompts

Prompts to paste into Claude Code, Cursor, Codex in ChatGPT or any MCP client once ButterKit is connected (setup is in the [main README](../../README.md#connect-your-ai-agent)). Your agent picks the right ButterKit tools, so plain language works. Swap in your own app name, paths and languages.

## Start a project

```text
Create a new ButterKit document for my app Trailhead. Add five iPhone artboards using
the Sahara template, and put the screenshots from ~/Desktop/trailhead-shots on the devices
in filename order.
```

```text
Open ~/Projects/Trailhead/Marketing/Trailhead.butterkit and tell me which artboards,
languages and devices it has.
```

## Design

```text
On every iPhone artboard, set the headline to a short benefit in under five words and the
subtitle to one supporting line. Base them on what each screenshot shows.
```

```text
Give all base artboards a gradient background from #FFD149 at the top to #F2A70E at the
bottom, then show me a preview of the first artboard.
```

```text
Link ~/Projects/Trailhead/fastlane/butterkit as the screenshot folder and refresh it.
Tell me if any device folders didn't match.
```

## Localize

```text
Add German, Japanese, French (France) and Brazilian Portuguese, and translate all text.
Then list any text blocks where the translation is much longer than the English.
```

```text
Translate my App Store description, promotional text and What's New into every language
in this document.
```

## Publish to App Store Connect

```text
Check my App Store Connect connection, find the app named Trailhead, and list its
editable versions.
```

```text
Upload screenshots and metadata for en-US and de-DE to Trailhead version 2.4.
```

## End to end

```text
Use ButterKit to add Italian to my screenshots, translate them, and upload them to
App Store Connect.
```

```text
I just ran fastlane. Refresh the linked screenshots in Trailhead.butterkit, export every
artboard as PNG to ~/Desktop/trailhead-export, and summarize what changed.
```

## Tips

- **Say which document.** If more than one is open, name the file so your agent targets the right one.
- **Ask for a preview.** Agents can render any artboard and look at it before moving on.
- **Uploads are real.** Uploading changes your live App Store Connect listing, so review before you ask for it. ButterKit only uploads to versions App Store Connect still allows editing.

The full tool list is in the [MCP docs](https://butterkit.app/docs/mcp/?utm_source=github).
