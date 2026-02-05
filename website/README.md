# Cardly Website

Landing page for the Cardly mobile app. This is a static website built with HTML, CSS, and vanilla JavaScript.

## 🚀 Quick Start

### Local Development

Simply open `index.html` in your browser, or use a local server:

```bash
# Using Python
python -m http.server 8000

# Using Node.js (http-server)
npx http-server

# Using PHP
php -S localhost:8000
```

Then visit `http://localhost:8000`

## 📁 Structure

```
website/
├── index.html          # Main landing page
├── css/
│   └── style.css      # Stylesheet
├── js/
│   └── main.js        # JavaScript for interactions
├── images/            # Images and assets
│   ├── logo.png
│   └── screenshots/
└── downloads/         # APK/IPA files for download
```

## 🌐 Deployment

### GitHub Pages

1. Push to GitHub
2. Go to repository Settings → Pages
3. Select branch: `main`
4. Select folder: `/website` or `/ (root)`
5. Save and wait for deployment

Your site will be live at: `https://yourusername.github.io/cardly`

### Alternative Hosting

- **Netlify**: Drag and drop the `website` folder
- **Vercel**: Import from GitHub
- **Firebase Hosting**: `firebase deploy`
- **Cloudflare Pages**: Connect your repo

## 📝 Customization

### Update Content

Edit `index.html` to change content, links, and download URLs.

### Styling

Modify `css/style.css`. Key CSS variables are at the top:

```css
:root {
  --primary-color: #0175c2;
  --secondary-color: #02569b;
  /* ... more variables */
}
```

### Add Screenshots

Place app screenshots in `images/` and update the image references in `index.html`.

### Download Links

Add your APK file to `downloads/` folder and update the link in the Download section.

## 🔗 Links to Update

Before deploying, replace these placeholders in `index.html`:

- `yourusername` → Your GitHub username
- `support@cardly.app` → Your contact email
- Download button href → Actual APK path

## 📱 Features

- ✅ Fully responsive design
- ✅ Smooth scroll animations
- ✅ Mobile-friendly navigation
- ✅ SEO optimized
- ✅ Fast loading
- ✅ No dependencies

## 📄 License

Same as the main Cardly project - MIT License
