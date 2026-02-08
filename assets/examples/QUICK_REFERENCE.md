# Import Format Quick Reference

## 🎴 Supported Card Types

### 1. ✏️ Basic Cards (Front/Back)

**Columns:**

```
front,back,frontHint,backHint,labels
```

**Minimum:**

```
front,back
```

**Example:**

```csv
front,back,frontHint,backHint,labels
What is 2+2?,4,Basic math,Simple addition,math basic
Hydrogen symbol,H,First element,Periodic table,science chemistry
```

**Column Aliases:**

- `front` = `question` = `word`
- `back` = `answer` = `definition`
- `labels` = `tags` = `label` = `tag`

---

### 2. 🖼️ Image Cards (Image with Text)

**Columns:**

```
imageUrl,word,frontHint,backHint,labels
```

**Minimum:**

```
imageUrl,word
```

**Example:**

```csv
imageUrl,word,frontHint,backHint,labels
https://example.com/cat.jpg,Cat,4 legs,Pet animal,animal pet
https://example.com/dog.jpg,Dog,Man's best friend,Barks,animal pet domestic
```

**Column Aliases:**

- `imageUrl` = `image`
- `word` = `text` = `answer`
- `labels` = `tags` = `label` = `tag`

---

### 3. 🔺 Triple Cards (3 Faces)

**Columns:**

```
face1,face2,face3,frontHint,labels
```

**Minimum:**

```
face1,face2,face3
```

**Example:**

```csv
face1,face2,face3,frontHint,labels
Hello,Bonjour,Hola,Greeting in English/French/Spanish,language greetings
Goodbye,Au revoir,Adiós,Farewell,language greetings
Thank you,Merci,Gracias,Gratitude,language polite
```

**Note:** Only `frontHint` supported (or `hint`)

---

## 🏷️ Labels (NEW!)

**What are labels?**

- Tags for organizing and filtering cards
- Space-separated (e.g., "math geometry basic")
- Optional for all card types
- Can be empty for individual cards

**Examples:**

- `math basic` - Two labels
- `language french greetings` - Three labels
- `` (empty) - No labels
- `programming` - One label

**Best practices:**

- Use lowercase
- Keep short and simple
- Be consistent
- Use spaces not commas

---

## 🔍 Auto-Detection Rules

| If file contains...   | Detected as... |
| --------------------- | -------------- |
| `face1,face2,face3`   | Triple Card 🔺 |
| `imageUrl` or `image` | Image Card 🖼️  |
| `front,back`          | Basic Card ✏️  |
| 3+ columns, no header | Triple Card 🔺 |
| 2 columns, no header  | Basic Card ✏️  |

---

## 📊 File Format

**Delimiter:** Comma (`,`)  
**Encoding:** UTF-8  
**Extension:** `.csv`  
**Headers:** Optional but recommended

## ✅ Valid Row Rules

### Basic Card Row:

- ✅ `Hello,Greeting`
- ✅ `Hello,Greeting,,,` (empty hints and labels)
- ✅ `Hello,Greeting,,math basic` (labels only)
- ✅ `Hello,Greeting,Hint,Hint,math` (all fields)
- ❌ `Hello,` (missing back)
- ❌ `,Greeting` (missing front)

### Image Card Row:

- ✅ `https://img.url,Word`
- ✅ `https://img.url,Word,,,animal` (with labels)
- ✅ `https://img.url,Word,Hint,Hint,animal pet`
- ❌ `https://img.url,` (missing word)

### Triple Card Row:

- ✅ `En,Fr,Es`
- ✅ `En,Fr,Es,,language` (labels only)
- ✅ `En,Fr,Es,Hint,language greetings`
- ❌ `En,Fr,` (missing face3)

## 📝 Header Variations

All these are valid and recognized:

**Basic Cards:**

- `front,back`
- `question,answer`
- `word,definition`
- `front,back,labels`
- `front,back,frontHint,backHint,labels`

**Image Cards:**

- `imageUrl,word`
- `image,text`
- `imageUrl,word,labels`
- `imageUrl,word,frontHint,backHint,labels`

**Triple Cards:**

- `face1,face2,face3`
- `face1,face2,face3,labels`
- `face1,face2,face3,hint,labels`
- `face1,face2,face3,frontHint,labels`

## 🎯 Quick Examples

### Minimal Basic Card File

```csv
front,back,labels
Apple,Fruit,food
Dog,Animal,animals pets
```

### Full Basic Card File

```csv
front,back,frontHint,backHint,labels
What is H2O?,Water,Chemical formula,Common liquid,science chemistry
What is CO2?,Carbon dioxide,Greenhouse gas,You exhale this,science chemistry
```

### Minimal Image Card File

```csv
imageUrl,word,labels
https://example.com/apple.jpg,Apple,fruit food
https://example.com/banana.jpg,Banana,fruit food yellow
```

### Full Image Card File

```csv
imageUrl,word,frontHint,backHint,labels
https://example.com/cat.jpg,Cat,Pet,Meows,animal pet domestic
https://example.com/dog.jpg,Dog,Pet,Barks,animal pet domestic
```

### Minimal Triple Card File

```csv
face1,face2,face3,labels
Hello,Bonjour,Hola,language greetings
Goodbye,Au revoir,Adiós,language greetings
```

### Full Triple Card File

```csv
face1,face2,face3,frontHint,labels
Hello,Bonjour,Hola,Greeting: English/French/Spanish,language greetings basic
Goodbye,Au revoir,Adiós,Farewell in 3 languages,language greetings basic
```

## ⚡ Pro Tips

1. **Headers optional but recommended** - Makes file more readable
2. **Leave hints blank if not needed** - `Hello,Greeting,,,` is valid
3. **Labels are space-separated** - Use `math basic` not `math,basic`
4. **Quotes for commas in text** - `"Text, with comma",Answer`
5. **Case insensitive headers** - `Front` = `front` = `FRONT`
6. **Mixed card types not supported** - One file = One card type
7. **Image URLs must be complete** - Include `https://`
8. **Empty rows ignored** - Blank lines automatically skipped
9. **Only comma delimiter** - Tab and semicolon no longer supported
10. **UTF-8 encoding** - Required for emoji and special characters

## 🔗 See Also

- `IMPORT_FORMAT_GUIDE.md` - Complete technical documentation
- `EXAMPLES_README.md` - Detailed example file descriptions
- Example files in `basic_cards/`, `image_cards/`, `triple_cards/`
