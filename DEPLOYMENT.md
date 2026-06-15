# Deployment Guide: JSON Formatter Pro

This document provides step-by-step instructions to optimize, build, and deploy **JSON Formatter Pro** for production.

---

## 1. Web Build Optimization

Flutter Web offers two rendering engines:
- **CanvasKit (Recommended for Desktop/Tablet)**: High performance, fully custom pixel rendering, but adds ~1.5MB to the initial download size.
- **HTML (Recommended for Mobile/SEO)**: Faster loading, uses standard HTML elements, but might render text/complex shadows slightly differently.

### Recommended Build Command
For a SaaS utility tool like JSON Formatter Pro, the **auto** renderer is recommended. It uses HTML for mobile browsers and CanvasKit for desktop browsers:
```bash
flutter build web --release --web-renderer auto
```

---

## 2. Deployment Targets

### A. Firebase Hosting (Recommended)
Firebase Hosting provides SSD-backed hosting and global CDN out-of-the-box.

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```
2. Log in to your Firebase account:
   ```bash
   firebase login
   ```
3. Initialize hosting in the project root:
   ```bash
   firebase init hosting
   ```
   - Select your project.
   - Set the public directory to: `build/web`
   - Configure as a single-page app: `Yes`
   - Set up automatic builds and deploys with GitHub: `Optional`
4. Deploy the site:
   ```bash
   firebase deploy --only hosting
   ```

---

### B. Vercel
Vercel is a global edge network for static assets.

1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```
2. Run vercel configuration in the project root:
   ```bash
   vercel
   ```
   - Link to a new project.
   - Choose default configuration.
   - When prompted for output directory, override it to `build/web`.
3. To deploy to production:
   ```bash
   vercel --prod
   ```

---

### C. Netlify
Netlify offers automated continuous deployment from git.

1. Install Netlify CLI:
   ```bash
   npm install -g netlify-cli
   ```
2. Log in and initialize:
   ```bash
   netlify login
   ```
3. Deploy:
   ```bash
   netlify deploy --dir=build/web --prod
   ```

---

### D. GitHub Pages
Perfect for free open-source repository hosting.

1. Build the release with the base-href set to your repository name:
   ```bash
   flutter build web --release --base-href "/json_formatter_pro/"
   ```
2. Install the `gh-pages` helper package:
   ```bash
   npm install -g gh-pages
   ```
3. Publish the `build/web` folder:
   ```bash
   gh-pages -d build/web
   ```

---

## 3. Web Performance Best Practices

1. **Gzip / Brotli Compression**: Ensure your hosting provider compresses static files (JS, CSS, WASM, JSON). This reduces load times by up to 70%.
2. **Cache Headers**: Cache static fonts, CanvasKit WebAssembly files, and images.
   - Cache-Control: `public, max-age=31536000, immutable` for assets under `assets/` and CanvasKit files.
   - Cache-Control: `no-cache` or `max-age=0` for `index.html` and `version.json` to prevent users from loading stale bundles.
