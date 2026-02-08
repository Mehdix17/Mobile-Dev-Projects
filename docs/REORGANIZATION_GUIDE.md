# 🔄 Repository Reorganization Guide

This guide will help you reorganize your repository to separate the mobile app and website.

## Current Structure

```
cardly/
├── lib/              # Flutter app
├── android/
├── ios/
├── assets/
├── website/          # ✅ Already created
├── pubspec.yaml
└── README.md
```

## Option 1: Keep Current Structure (Recommended)

**This is the easiest option and works well!**

Your current structure is already good. The website is in `/website` and the mobile app is in the root. This is a common monorepo pattern.

### What you need to do:

1. **Replace the root README** with the monorepo version:

   ```bash
   mv README.md MOBILE_README.md
   mv ROOT_README.md README.md
   ```

2. **Copy logo to website**:

   ```bash
   # Already done! But if needed:
   cp assets/images/logo.png website/images/logo.png
   ```

3. **Update links in website/index.html**:
   - Replace `yourusername` with your GitHub username
   - Update email addresses
   - Update repository URLs

4. **Commit and push**:

   ```bash
   git add .
   git commit -m "Add landing page website"
   git push origin main
   ```

5. **Enable GitHub Pages**:
   - Go to: Settings → Pages
   - Source: Deploy from branch `main`
   - Folder: `/website`
   - Save

## Option 2: Full Reorganization (Advanced)

If you want everything in separate folders:

```
cardly/
├── mobile/           # Flutter app (moved)
├── website/          # Landing page (already exists)
└── README.md         # Monorepo README
```

### Steps:

1. **Create mobile directory**:

   ```bash
   mkdir mobile
   ```

2. **Move Flutter files** (Git-aware):

   ```bash
   git mv lib mobile/
   git mv android mobile/
   git mv ios mobile/
   git mv assets mobile/
   git mv test mobile/
   git mv pubspec.yaml mobile/
   git mv analysis_options.yaml mobile/
   ```

3. **Move config files**:

   ```bash
   git mv firebase.json mobile/
   git mv devtools_options.yaml mobile/
   git mv english_flashcard_app.iml mobile/
   ```

4. **Update README**:

   ```bash
   git mv README.md mobile/README.md
   git mv ROOT_README.md README.md
   ```

5. **Update paths in workflows**:
   Edit `.github/workflows/flutter-ci.yml`:

   ```yaml
   paths:
     - 'mobile/**'

   # Add before flutter commands:
   - name: Change directory
     run: cd mobile
   ```

6. **Update .gitignore paths** if needed

7. **Commit changes**:
   ```bash
   git add .
   git commit -m "Reorganize: separate mobile and website"
   git push origin main
   ```

## Quick Commands (Option 1 - Recommended)

Copy and paste these commands:

```bash
# Navigate to project
cd c:/Users/mehdi/OneDrive/Bureau/flutter_projects/cardly

# Backup current README
cp README.md docs/MOBILE_APP_README.md 2>/dev/null || cp README.md MOBILE_APP_README.md

# Replace with monorepo README
cp ROOT_README.md README.md

# Update website links (you'll need to do this manually)
# Edit website/index.html and replace:
# - yourusername → your GitHub username
# - support@cardly.app → your email

# Commit changes
git add .
git commit -m "feat: Add landing page website

- Add responsive HTML/CSS/JS website
- Add GitHub Actions for auto-deployment
- Update README for monorepo structure
- Add deployment documentation"

git push origin main
```

## What's Already Done ✅

- ✅ Website folder created
- ✅ Landing page HTML/CSS/JS created
- ✅ GitHub Actions workflows created
- ✅ Website README created
- ✅ Deployment guide created
- ✅ Logo copied to website
- ✅ .gitignore updated

## Next Steps 🎯

1. **Update Links**:
   - Edit `website/index.html`
   - Replace `yourusername` with your GitHub username
   - Update email and social links

2. **Add Screenshots**:
   - Take app screenshots
   - Add to `website/images/`
   - Update image references in HTML

3. **Build APK**:

   ```bash
   flutter build apk --release
   cp build/app/outputs/flutter-apk/app-release.apk \
      website/downloads/cardly-latest.apk
   ```

4. **Commit and Push**:

   ```bash
   git add .
   git commit -m "Update website content and add APK"
   git push origin main
   ```

5. **Enable GitHub Pages**:
   - Repository Settings → Pages
   - Source: `main` branch
   - Folder: `/website`
   - Save

6. **Test Your Website**:
   - Visit: `https://yourusername.github.io/cardly`

## Testing Locally 🧪

### Test Website:

```bash
cd website
python -m http.server 8000
# Visit: http://localhost:8000
```

### Test Mobile App:

```bash
flutter run
```

## Troubleshooting 🔧

### Website not showing?

- Check GitHub Actions (Actions tab)
- Wait 5-10 minutes after push
- Clear browser cache

### Links broken?

- Check you replaced `yourusername`
- Verify paths are correct
- Test locally first

### Need help?

- Review `DEPLOYMENT.md`
- Check GitHub Actions logs
- Open an issue

## Summary

**Recommended**: Stick with Option 1 (current structure). It's clean, simple, and works perfectly!

Just:

1. Replace README
2. Update links in website
3. Push to GitHub
4. Enable GitHub Pages

Done! 🎉
