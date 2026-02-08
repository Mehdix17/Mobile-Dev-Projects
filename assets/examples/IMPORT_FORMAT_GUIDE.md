# Import Format Guide

Cardly supports importing flashcards from various file formats. This guide explains the supported formats and how to structure your import files.

## Supported File Formats

### 1. CSV (Comma-Separated Values)

**File Extension:** `.csv`

#### Basic Format

```csv
front,back
Hello,A greeting
Goodbye,A farewell
Thank you,Expressing gratitude
```

#### With Notes/Hints (Optional 3rd Column)

```csv
front,back,notes
Hello,A greeting,Common informal greeting
Goodbye,A farewell,Used when parting ways
```

#### Quotes for Complex Text

```csv
front,back
"How are you?","A common question"
"What is 2+2?","The answer is 4"
"Text with, commas","Needs to be quoted"
```

### 2. Tab-Separated Text

**File Extensions:** `.txt`, `.tsv`

```
front	back
Hello	A greeting
Goodbye	A farewell
```

### 3. Semicolon-Separated

**File Extension:** `.csv`

Useful for European locales where comma is a decimal separator.

```csv
front;back
Hello;A greeting
Goodbye;A farewell
```

## Format Rules

### Headers (Optional)

The first row can optionally be a header row. The following header combinations are recognized and will be skipped:

- `front,back`
- `question,answer`
- `word,definition`

If the first row doesn't match these patterns, it will be treated as a card.

### Delimiters

Auto-detected based on content:

1. **Tab** (`\t`) - Detected first if present
2. **Comma** (`,`) - Default
3. **Semicolon** (`;`) - Used if found and no commas present

### Column Structure

#### Minimum Required (2 columns):

- **Column 1:** Front of card (question/word)
- **Column 2:** Back of card (answer/definition)

#### Optional (3+ columns):

- **Column 3:** Notes/hints (stored but not currently displayed in all card types)
- **Columns 4+:** Ignored

### Text Encoding

- UTF-8 encoding recommended
- Special characters supported (é, ñ, ü, etc.)
- Emoji supported 🎉

### Line Endings

Supports all common line endings:

- Unix (`\n`)
- Windows (`\r\n`)
- Mac Classic (`\r`)

## Import Process

1. **File Selection:** Choose a `.csv`, `.txt`, or `.tsv` file
2. **Parsing:** File is automatically parsed with delimiter detection
3. **Deck Creation:** A new deck is created with the filename (without extension)
4. **Card Import:** All valid rows become flashcards
5. **Status:** Cards start as "New" and ready for study

## Examples

### Example 1: Simple Vocabulary

```csv
front,back
Apple,A red fruit
Banana,A yellow fruit
Orange,A citrus fruit
```

### Example 2: Language Learning

```csv
question,answer
How do you say hello in French?,Bonjour
How do you say goodbye in French?,Au revoir
How do you say thank you in French?,Merci
```

### Example 3: Study Notes

```csv
front,back,notes
Photosynthesis,Process where plants make food,Requires sunlight and chlorophyll
Mitosis,Cell division,Results in two identical cells
DNA,Genetic material,Deoxyribonucleic acid
```

### Example 4: Math Problems

```csv
front,back
"What is 5 × 6?",30
"What is 12 ÷ 4?",3
"What is 15 + 23?",38
```

## Tips for Creating Import Files

1. **Use Excel or Google Sheets:** Create your cards in a spreadsheet, then export as CSV
2. **Test with Small Files:** Start with 5-10 cards to verify format
3. **Check Encoding:** Save as UTF-8 to avoid character issues
4. **Quote Complex Text:** Use quotes around text containing commas or special characters
5. **One Card Per Row:** Each row becomes exactly one flashcard
6. **No Empty Rows:** Remove blank rows before importing

## Common Issues

### Issue: "No valid cards found"

**Solution:** Ensure each row has at least 2 non-empty columns

### Issue: Cards not splitting correctly

**Solution:** Check delimiter - might need to use tab-separated instead of comma

### Issue: Special characters showing incorrectly

**Solution:** Save file as UTF-8 encoding

### Issue: First card is missing

**Solution:** Your first row is being treated as a header. Either:

- Remove the header row, or
- Use different column names (not front/back, question/answer, or word/definition)

## Future Format Support

Coming soon:

- JSON backup files
- Anki package (.apkg) import
- Quizlet export format
- Image-based cards with URLs

## Need Help?

If you're having trouble importing cards:

1. Check the example files in `assets/examples/`
2. Verify your file matches one of the supported formats
3. Try the "Import from Text" option for tab-separated files
4. Contact support with a sample of your file (first 3 rows)
