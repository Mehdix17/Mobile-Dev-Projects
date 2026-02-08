# CSV Import Examples

This folder contains comprehensive example files demonstrating all supported import formats for Cardly.

## 📁 Folder Structure

```
examples/
├── basic_cards/          # Basic front/back flashcards
├── image_cards/          # Cards with images
├── triple_cards/         # Three-face cards (e.g., multi-language)
└── README.md            # This file
```

## 🎴 Card Types

### 1. Basic Cards (front/back)

**Location:** `basic_cards/`

Simple question/answer or word/definition cards.

**Format:**

```csv
front,back,frontHint,backHint,labels
```

**Examples:**

- `01_minimal_basic.csv` - Minimal with labels (3 columns)
- `02_with_front_hints.csv` - Front hints and labels (4 columns)
- `03_with_all_hints.csv` - All fields including labels (5 columns)
- `04_vocabulary_simple.csv` - SAT/GRE vocabulary
- `05_math_problems.csv` - Math Q&A with hints and labels
- `06_history_dates.csv` - Historical events
- `07_science_facts.csv` - Science knowledge
- `08_with_special_characters.csv` - Special chars and quotes
- `09_emoji_cards.csv` - Using emoji in cards
- `10_programming_terms.csv` - Computer science terms

---

### 2. Image Cards (image with text)

**Location:** `image_cards/`

Visual learning with images and text answers.

**Format:**

```csv
imageUrl,word,frontHint,backHint,labels
```

**Examples:**

- `01_minimal_image.csv` - URL, word, and labels (3 columns)
- `02_with_hints.csv` - With hints and labels (5 columns)
- `03_animals.csv` - Animal identification
- `04_countries_flags.csv` - Flag recognition
- `05_landmarks.csv` - Famous landmarks

**Note:** Uses real Unsplash and flag CDN URLs for working examples.

---

### 3. Triple Cards (3 faces)

**Location:** `triple_cards/`

Multi-perspective cards (e.g., English/French/Spanish translations).

**Format:**

```csv
face1,face2,face3,frontHint,labels
```

**Examples:**

- `01_minimal_triple.csv` - 3 faces and labels (4 columns)
- `02_with_hints.csv` - With hints and labels (5 columns)
- `03_numbers.csv` - Numbers in 3 languages
- `04_colors.csv` - Color names
- `05_food_terms.csv` - Food vocabulary
- `06_english_french_german.csv` - Different language set
- `07_chemistry_elements.csv` - Name/Symbol/Number
- `08_state_capital_abbr.csv` - State/Capital/Abbr

---

## 🚀 Quick Start

### Try an Example:

1. Open Cardly app
2. Go to **Marketplace** → **Import Deck**
3. Select **Import from CSV**
4. Choose any example file from this folder
5. New deck created instantly!

### Recommended Starting Files:

- **First time?** → `basic_cards/01_minimal_basic.csv`
- **Want hints?** → `basic_cards/03_with_all_hints.csv`
- **Visual learner?** → `image_cards/02_with_hints.csv`
- **Learning languages?** → `triple_cards/02_with_hints.csv`

---

## 📊 Column Requirements

### Basic Cards

| Column    | Required | Description                                  |
| --------- | -------- | -------------------------------------------- |
| front     | ✅ Yes   | Question/Word                                |
| back      | ✅ Yes   | Answer/Definition                            |
| frontHint | ❌ No    | Hint for front                               |
| backHint  | ❌ No    | Hint for back                                |
| labels    | ❌ No    | Space-separated tags (e.g., "math geometry") |

### Image Cards

| Column    | Required | Description                               |
| --------- | -------- | ----------------------------------------- |
| imageUrl  | ✅ Yes   | Image URL                                 |
| word      | ✅ Yes   | Text answer                               |
| frontHint | ❌ No    | Hint for image                            |
| backHint  | ❌ No    | Hint for word                             |
| labels    | ❌ No    | Space-separated tags (e.g., "animal pet") |

### Triple Cards

| Column    | Required | Description                                    |
| --------- | -------- | ---------------------------------------------- |
| face1     | ✅ Yes   | First perspective                              |
| face2     | ✅ Yes   | Second perspective                             |
| face3     | ✅ Yes   | Third perspective                              |
| frontHint | ❌ No    | General hint                                   |
| labels    | ❌ No    | Space-separated tags (e.g., "language french") |

---

## 🏷️ Labels Feature

**NEW:** All cards now support labels (also called tags) for better organization!
,`3. **Labels are optional** - Leave labels column empty if not needed
4. **Use quotes for commas** -`"Text, with comma",Answer`5. **Only comma delimiter** - CSV files must use comma (,) as delimiter
6. **UTF-8 for emojis** - Save with UTF-8 encoding for 🎉 support
7. **Image URLs** - Must be complete:`https://...`8. **No mixed types** - One file = One card type
9. **Space-separated labels** -`math basic`not`math,basic`

- Examples: `math geometry`, `language french basic`, `science biology`

**Example:**

```csv
front,back,labels
What is 2+2?,4,math basic
Bonjour,Hello,language french
Capital of France?,Paris,geography europe
```

**Benefits:**

- Filter cards by label
- Organize large decks
- Create custom study sessions
- Track progress by category

---

## 💡 Tips

1. **Headers are flexible** - Use `question,answer` or `word,definition` instead of `front,back`
2. **Leave hints blank** - Empty cells are OK: `Hello,Greeting,,`
3. **Use quotes for commas** - `"Text, with comma",Answer`
4. **Mix & match delimiters** - App auto-detects comma, tab, or semicolon
5. **UTF-8 for emojis** - Save with UTF-8 encoding for 🎉 support
6. **Image URLs** - Must be complete: `https://...`
7. **No mixed types** - One file = One card type

---

## 🔍 Use Cases

### Study Scenarios:

| Scenario            | Recommended Folder | Example File              |
| ------------------- | ------------------ | ------------------------- |
| Vocabulary building | basic_cards        | 04_vocabulary_simple.csv  |
| Math practice       | basic_cards        | 05_math_problems.csv      |
| History exam        | basic_cards        | 06_history_dates.csv      |
| Language learning   | triple_cards       | 02_with_hints.csv         |
| Visual memorization | image_cards        | 03_animals.csv            |
| Programming study   | basic_cards        | 10_programming_terms.csv  |
| Geography           | image_cards        | 04_countries_flags.csv    |
| Chemistry           | triple_cards       | 07_chemistry_elements.csv |

---

## 📝 Creating Your Own

### Easy Method (Spreadsheet):

1. Open Excel or Google Sheets
2. Copy format from any example
3. Replace with your data
4. File → Download/Export as CSV
5. Import to Cardly

### Advanced Method (Text Editor):

1. Copy any example file
2. Open in VS Code, Notepad++, etc.
3. Edit directly
4. Save as `.csv` with UTF-8 encoding
5. Import to Cardly

---

## 🎯 File Naming Convention

Examples follow this pattern:

```
NN_descriptive_name.csv
```

- `NN` = Number (01, 02, 03...)
- Helps sort files logically
- Use underscores instead of spaces

---

## ⚠️ Common Mistakes

❌ **Wrong:** Missing required columns

```csv
front
Hello
Goodbye
```

✅ **Right:** At least 2 columns

```csv
front,back
Hello,Greeting
Goodbye,Farewell
```

---

❌ **Wrong:** Mixed card types in one file

```csv
front,back
Hello,Greeting
https://img.url,Word
```

✅ **Right:** One card type per file

```csv
front,back
Hello,Greeting
Goodbye,Farewell
```

---

❌ **Wrong:** Unquoted comma in text

```csv
front,back
Hello, friend,Greeting
```

✅ **Right:** Quote text with commas

```csv
front,back
"Hello, friend",Greeting
```

---

## 📚 Additional Resources

- **QUICK_REFERENCE.md** - Quick lookup guide
- **IMPORT_FORMAT_GUIDE.md** - Complete technical docs
- **EXAMPLES_README.md** - Detailed format explanations

---

## 🤝 Contributing

Want to add more examples?

1. Follow the naming convention
2. Include appropriate hints
3. Test import in Cardly
4. Ensure UTF-8 encoding
5. Add description to this README

---

## 📄 License

These examples are free to use, modify, and distribute.

---

**Happy Learning! 🎓**
