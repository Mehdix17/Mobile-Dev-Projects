# CSV Import Format Examples

This folder contains example CSV files demonstrating all supported card types and formats for importing into Cardly.

## 📁 Example Files

### Basic Cards

- **`example_import.csv`** - Simple cards with hints
  - Format: `front,back,frontHint,backHint`
  - Best for: Vocabulary, definitions, Q&A

### Basic Cards (Alternative)

- **`example_import_with_notes.csv`** - Same as above with complete hints
  - Format: `front,back,frontHint,backHint`
  - All columns filled with example hints

### Image Cards

- **`example_import_image_cards.csv`** - Cards with image URLs
  - Format: `imageUrl,word,frontHint,backHint`
  - Best for: Visual learning, object recognition, vocabulary with pictures
  - Uses Unsplash image URLs as examples

### Triple Cards (3 Faces)

- **`example_import_triple_cards.csv`** - Multi-language or multi-facet cards
  - Format: `face1,face2,face3,frontHint`
  - Best for: Multiple language translation, related concepts

### Semicolon Separated

- **`example_import_semicolon.csv`** - European locale format
  - Format: `front;back` (semicolon delimiter)
  - Best for: Regions where comma is decimal separator

### Tab Separated

- **`example_import_tab_separated.txt`** - Tab-delimited format
  - Format: `front[TAB]back`
  - Best for: Copy-paste from Excel/spreadsheets

## 🎯 Card Type Detection

Cardly **automatically detects** card type from column headers:

| Headers                 | Detected Type | Icon |
| ----------------------- | ------------- | ---- |
| `front,back,...`        | Basic Card    | ✏️   |
| `imageUrl,word,...`     | Image Card    | 🖼️   |
| `face1,face2,face3,...` | Triple Card   | 🔺   |

## 📋 Column Reference

### Basic Cards

- **Required:**
  - `front` or `question` or `word` (column 1)
  - `back` or `answer` or `definition` (column 2)
- **Optional:**
  - `frontHint` (column 3)
  - `backHint` (column 4)

### Image Cards

- **Required:**
  - `imageUrl` or `image` (column 1) - URL to image
  - `word` or `text` or `answer` (column 2) - Text answer
- **Optional:**
  - `frontHint` (column 3)
  - `backHint` (column 4)

### Triple Cards

- **Required:**
  - `face1` (column 1) - First language/concept
  - `face2` (column 2) - Second language/concept
  - `face3` (column 3) - Third language/concept
- **Optional:**
  - `frontHint` or `hint` (column 4) - General hint

## 🔧 Supported Delimiters

All automatically detected:

- **Comma** (`,`) - Standard CSV
- **Tab** (`\t`) - TSV/Text files
- **Semicolon** (`;`) - European format

## 💡 Usage Tips

1. **Headers are optional** but recommended for clarity
2. **Hints are always optional** - leave blank if not needed
3. **Empty cells** are allowed for optional columns
4. **Quotes** around text containing delimiters: `"Text, with comma"`
5. **Image URLs** should be complete (https://...)
6. **UTF-8 encoding** supports all languages and emojis

## 📝 Creating Your Own

### Method 1: Copy and Edit

1. Download any example file
2. Open in Excel, Google Sheets, or text editor
3. Replace data with your own
4. Save as CSV

### Method 2: Create from Scratch

```csv
front,back,frontHint,backHint
Your question,Your answer,Optional hint,Optional hint
```

### Method 3: Export from Spreadsheet

1. Create data in Excel/Sheets
2. Ensure first row has correct headers
3. File → Download/Export as CSV

## ⚠️ Common Issues

**Issue:** "No valid cards found"

- **Fix:** Ensure headers match supported names OR remove header row

**Issue:** Wrong card type imported

- **Fix:** Use correct header names (see table above)

**Issue:** Hints not imported

- **Fix:** Ensure hint columns come after required fields

**Issue:** Images not showing

- **Fix:** Verify image URLs are accessible and complete

## 🔗 Related Files

- **`IMPORT_FORMAT_GUIDE.md`** - Complete technical documentation
- **`README.md`** - Quick start guide

## 🚀 Try It!

1. Go to Marketplace → Import Deck
2. Choose "Import from CSV"
3. Select any example file
4. New deck created automatically!
