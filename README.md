# JSON Formatter Pro

A complete production-ready, SaaS-grade developer utility platform built with Flutter Web. **JSON Formatter Pro** provides a suite of advanced developer tools to validate, format, minify, visualize, compare, and convert JSON data cleanly, securely, and with unmatched performance.

## Key Features

- **JSON Formatter & Validator**: Beautify JSON with custom indentation spacing (2 spaces, 4 spaces, or Tabs). Detailed coordinates reporting (line & column numbers) with clear syntax error explanations.
- **Minifier**: Strip unnecessary white space and line breaks for payload optimization.
- **Tree Viewer**: Virtualized, lazy-loaded tree rendering to browse extremely large JSON files (up to 10MB) instantly without UI stutters. Integrated node search with auto-expanding paths and highlight tracking.
- **Side-by-Side Comparator**: Compare two JSON files with synchronized vertical scrolling. Color-coded differences (added, removed, modified) and visual metrics display.
- **Dart Model Generator**: Convert JSON structures recursively into null-safe, fully structured Dart models with `fromJson` factories and `toJson` serializers.
- **YAML Converter**: High-fidelity live JSON-to-YAML compiler supporting proper spacing, array indicators, and text escaping.
- **Settings Panel**: Customize editor configurations (font size, monospace font family, word wrapping, line numbers) and theme profiles.
- **Theme Support**: Seamless Dark Mode and Light Mode matching Material 3 specifications. Preferences are stored locally via `SharedPreferences`.

## Architecture & Technology Stack

- **Framework**: Flutter Web 3.x
- **Language**: Dart 3.x
- **State Management**: Riverpod 2.x (Notifier & Provider)
- **Routing**: GoRouter
- **Design System**: Material Design 3 (Sleek dark themes, Outfit and Inter Google Fonts typography)
- **Heavy Lift Isolation**: CPU-intensive operations (LCS Diffing, JSON validation/parsing, model generation, YAML formatting) run asynchronously on background thread **Isolates** via Flutter's `compute` method to guarantee 60FPS UI performance.

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl + Enter` | Format & Beautify JSON |
| `Ctrl + C` | Copy Editor JSON |
| `Ctrl + V` | Paste JSON from Clipboard |
| `Ctrl + F` | Toggle Text Find & Search |
| `Ctrl + S` | Download JSON file |
| `Ctrl + L` | Clear Editor |

## Running Locally

1. Install Flutter SDK (`^3.12.2`).
2. Run `flutter pub get` to download dependencies.
3. Start local development server:
   ```bash
   flutter run -d chrome
   ```

## Production Build & Deployment

Generate production web assets:
```bash
flutter build web --release
```

Deploy the generated `build/web/` bundle to:
- **Firebase Hosting**: Run `firebase init hosting` followed by `firebase deploy`.
- **Vercel** / **Netlify**: Deploy using static hosting profiles pointing to the build folder.
- **GitHub Pages**: Deploy using actions or direct branch publishing.
