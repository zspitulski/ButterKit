# fastlane to ButterKit

Capture your screenshots with fastlane, and ButterKit updates your designs on its own.

fastlane's `capture_screenshots` saves files as `screenshots/<locale>/<simulator name>-<screenshot name>.png`. ButterKit works best with a locale folder, then a device folder, then the images. These two files bridge the gap.

| File | What it does |
| --- | --- |
| [`Fastfile`](Fastfile) | A `butterkit_screenshots` lane that captures, then lays out the results |
| [`butterkit_folders.rb`](butterkit_folders.rb) | Copies each screenshot into `butterkit/<locale>/<device>/` |

## Set up

1. Copy both files into your project's `fastlane/` folder, or merge the lane into your existing Fastfile.
2. Edit `BUTTERKIT_DEVICES` so each simulator you capture on maps to a ButterKit device folder. The [linked folders guide](../linked-folders/README.md#device-folder-names) lists the names.
3. Set your UI test `scheme` and `languages`.
4. Run the lane once:

   ```bash
   bundle exec fastlane butterkit_screenshots
   ```

5. In ButterKit, deselect all artboards, click **Link screenshots folder…** in the Project Settings inspector, and choose `fastlane/butterkit`.

From then on, run the lane whenever your app changes. ButterKit notices the new images and drops them into the right devices, in every language.

## Tips

- **Name snapshots with a number.** `snapshot("01Home")` or `snapshot("Home-01")` keeps the order stable. ButterKit reads a trailing number first, then a leading one.
- **The folder stays put.** Each run empties and refills `fastlane/butterkit` but never deletes the folder itself, so ButterKit's link keeps working.
- **frameit isn't needed.** Framed copies are skipped, because ButterKit puts your screenshots in 3D devices itself.
- **iPhone Duo.** Add `cover` to a screenshot name, for example `snapshot("01-cover")`, to send it to the Duo's cover screen.
- **Ignore the output.** Add `fastlane/screenshots` and `fastlane/butterkit` to your `.gitignore`.
