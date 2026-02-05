# 🚀 Deployment Guide

Complete guide for deploying both the Cardly mobile app and website.

## 📱 Mobile App Deployment

### Android (Google Play Store)

#### Prerequisites

- Google Play Console account ($25 one-time fee)
- Signing key for your app
- App bundle or APK

#### Steps

1. **Create Signing Key**

   ```bash
   keytool -genkey -v -keystore ~/cardly-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias cardly-key
   ```

2. **Configure Signing** in `android/key.properties`:

   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=cardly-key
   storeFile=<path-to-jks>
   ```

3. **Build Release**

   ```bash
   flutter build appbundle --release
   # or
   flutter build apk --release
   ```

4. **Upload to Play Console**
   - Go to Google Play Console
   - Create new app
   - Upload app bundle
   - Fill in store listing
   - Submit for review

### iOS (App Store)

#### Prerequisites

- Apple Developer account ($99/year)
- macOS with Xcode
- App Store Connect access

#### Steps

1. **Configure Xcode Project**

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Set Bundle ID & Signing**
   - In Xcode: Runner → Signing & Capabilities
   - Set team and bundle identifier

3. **Build Archive**

   ```bash
   flutter build ios --release
   ```

4. **Upload to App Store Connect**
   - Product → Archive
   - Distribute App → App Store Connect
   - Fill in metadata
   - Submit for review

### Direct APK Distribution

For direct distribution (outside stores):

1. **Build Release APK**

   ```bash
   flutter build apk --release
   ```

2. **Copy APK**

   ```bash
   cp build/app/outputs/flutter-apk/app-release.apk \
      website/downloads/cardly-v1.0.0.apk
   ```

3. **Update Website**
   - Update version number in `website/index.html`
   - Update download link
   - Commit and push

## 🌐 Website Deployment

### Option 1: GitHub Pages (Recommended)

#### Setup

1. **Enable GitHub Pages**
   - Go to: Repository → Settings → Pages
   - Source: `Deploy from a branch`
   - Branch: `main`
   - Folder: `/website` or `/ (root)`
   - Save

2. **Automatic Deployment**
   - Workflow file already created: `.github/workflows/deploy-website.yml`
   - Pushes to `main` automatically deploy
   - Check: Actions tab on GitHub

3. **Custom Domain (Optional)**
   - Add `CNAME` file in website folder:
     ```
     cardly.app
     ```
   - Configure DNS:
     ```
     Type: CNAME
     Name: www
     Value: yourusername.github.io
     ```

#### URL

Your site: `https://yourusername.github.io/cardly`

### Option 2: Netlify

#### Setup

1. **Connect Repository**
   - Go to [Netlify](https://netlify.com)
   - New site from Git
   - Choose your repository

2. **Build Settings**

   ```
   Base directory: website
   Build command: (leave empty)
   Publish directory: .
   ```

3. **Deploy**
   - Automatic deployment on push
   - Free SSL certificate included
   - Custom domain support

#### URL

Your site: `https://your-site-name.netlify.app`

### Option 3: Vercel

#### Setup

1. **Import Project**
   - Go to [Vercel](https://vercel.com)
   - Import Git Repository

2. **Configure**

   ```
   Framework Preset: Other
   Root Directory: website
   Build Command: (leave empty)
   Output Directory: .
   ```

3. **Deploy**
   - Automatic deployment
   - Global CDN
   - Analytics included

#### URL

Your site: `https://cardly.vercel.app`

### Option 4: Firebase Hosting

#### Setup

1. **Install Firebase CLI**

   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize**

   ```bash
   firebase login
   firebase init hosting
   ```

3. **Configure** `firebase.json`:

   ```json
   {
     "hosting": {
       "public": "website",
       "ignore": ["firebase.json", "**/.*"]
     }
   }
   ```

4. **Deploy**
   ```bash
   firebase deploy --only hosting
   ```

#### URL

Your site: `https://your-project.web.app`

## 🔄 CI/CD Workflows

### GitHub Actions (Already Configured)

#### Mobile App CI

- File: `.github/workflows/flutter-ci.yml`
- Triggers: Push to main/develop
- Actions:
  - Analyze code
  - Run tests
  - Build APK
  - Upload artifacts

#### Website Deployment

- File: `.github/workflows/deploy-website.yml`
- Triggers: Push to main (website changes)
- Actions:
  - Deploy to GitHub Pages

### Manual Trigger

```bash
# Go to GitHub Actions tab
# Select workflow
# Click "Run workflow"
```

## 📋 Pre-Deployment Checklist

### Mobile App

- [ ] Update version in `pubspec.yaml`
- [ ] Test on real devices
- [ ] Update CHANGELOG.md
- [ ] Create release notes
- [ ] Run `flutter analyze`
- [ ] Run all tests
- [ ] Build release bundle
- [ ] Test release build

### Website

- [ ] Update version numbers
- [ ] Check all links work
- [ ] Test on multiple browsers
- [ ] Test mobile responsiveness
- [ ] Update screenshots
- [ ] Add latest APK to downloads
- [ ] Test download links
- [ ] Update metadata/SEO

## 🔒 Security

### Secrets Management

Store sensitive data in GitHub Secrets:

- Repository → Settings → Secrets and variables → Actions
- Add secrets:
  - `FIREBASE_TOKEN`
  - `PLAY_STORE_CREDENTIALS`
  - `APPLE_CERTIFICATE`

### Environment Variables

Never commit:

- API keys
- Firebase config (use `firebase_options.dart`)
- Signing keys
- Passwords

## 📊 Analytics & Monitoring

### Website Analytics

Add to `website/index.html`:

1. **Google Analytics**

   ```html
   <!-- Add before </head> -->
   <script
     async
     src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"
   ></script>
   ```

2. **Plausible (Privacy-friendly)**
   ```html
   <script
     defer
     data-domain="yourdomain.com"
     src="https://plausible.io/js/script.js"
   ></script>
   ```

### App Analytics

Already configured in Firebase.

## 🐛 Troubleshooting

### GitHub Pages not updating

- Check Actions tab for errors
- Clear browser cache
- Wait 5-10 minutes for CDN

### Build fails

- Check Flutter version matches
- Clear build folder: `flutter clean`
- Check dependencies: `flutter pub get`

### APK not installing

- Enable "Install from unknown sources"
- Check Android version compatibility
- Rebuild with correct signing

## 📞 Support

If deployment issues persist:

- Check [GitHub Actions logs](https://github.com/yourusername/cardly/actions)
- Review [Flutter docs](https://docs.flutter.dev/deployment)
- Open an [issue](https://github.com/yourusername/cardly/issues)
