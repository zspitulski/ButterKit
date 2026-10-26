# Linked screenshot folders

Link a folder of PNG or JPG screenshots to a ButterKit project and it places every image on the right device, in the right language, then keeps watching for changes. These are the layouts it understands, from simplest to most precise.

To link one, deselect all artboards, then click **Link screenshots folder…** in the Project Settings inspector. The full guide is in the [ButterKit docs](https://butterkit.app/docs/capture/images/link-fastlane-image-folder/?utm_source=github).

## Flat

Images directly in the folder. They go to the language you're viewing.

```
screenshots/
├── Settings-01.png
├── FeatureA-02.png
└── Exciting-03.png
```

## Locale folders

One folder per language. This is the layout most projects want.

```
screenshots/
├── en-US/
│   ├── Settings-01.png
│   └── FeatureA-02.png
└── de-DE/
    ├── Settings-01.png
    └── FeatureA-02.png
```

## Locale, then device folders

One folder per language, then one per device. Use this when a project has more than one kind of device, like iPhone and iPad.

```
screenshots/
├── en-US/
│   ├── iPhone 17 Pro Max/
│   │   ├── Settings-01.png
│   │   └── FeatureA-02.png
│   └── iPad/
│       ├── Settings-01.png
│       └── FeatureA-02.png
└── ja/
    ├── iPhone 17 Pro Max/
    └── iPad/
```

You can also skip the locale level and put device folders at the top. Their images go to the language you're viewing.

## Locale folder names

Use App Store Connect's locale codes, like `en-US`, `de-DE`, `ja` or `pt-BR`. Common variations work too, and a folder falls back to the closest language in your project, so `fr` fills French (France) when that's the French you have. ButterKit supports all 50 App Store Connect locales.

## Device folder names

Name a device folder after the device as it appears in ButterKit's device list, for example:

| Device in ButterKit | Folder name |
| --- | --- |
| iPhone 18 Pro Max | `iPhone 18 Pro Max` |
| iPhone 17 Pro Max | `iPhone 17 Pro Max` |
| iPhone Duo | `iPhone Duo` |
| iPad Pro 12.9″ | `iPad Pro 12.9` |
| iPad Pro 11″ | `iPad Pro 11` |
| MacBook Pro 16″ | `MacBook Pro 16` |
| Apple Watch Ultra | `Apple Watch Ultra` |
| Pixel 10 Pro | `Pixel 10 Pro` |

- **Family names work.** A folder named `iPhone` or `iPad` fills every device of that kind in the project.
- **Case and spacing are flexible.** `iphone 17 pro max` and `iPhone-17-Pro-Max` both match. Keep the words separate, though: `iphone17promax` won't.
- **Use ButterKit's names, not App Store Connect's.** `iPad Pro 13-inch (M4)` won't match. Use `iPad Pro 12.9` or just `iPad`.
- **Unmatched folders are reported.** If a device isn't in your project, ButterKit skips its folder and lists it in the scan summary.

## File order

ButterKit fills devices in filename order, artboard by artboard.

1. A trailing number wins: `Home-01.png`, `Home-02.png`.
2. Without one, a leading number is used: `01-Home.png`.
3. Otherwise, natural filename order.

Zero-pad your numbers. Without padding, `-2` sorts after `-10`.

When an artboard holds two of the same device, files go to the first device, then the second, then on to the next artboard.

## iPhone Duo

The Duo has an inner screen and a cover screen. Screenshots captured at the exact size of either screen go to that screen on their own. For anything else, put `cover` in the filename, like `01-cover.png`, to send it to the cover. A device folder with `cover` in its name sends its images to the cover too. Everything else goes to the inner screen.

## Automate it

The [fastlane example](../fastlane/README.md) captures screenshots and lays them out in the locale-then-device layout above, ready to link.
