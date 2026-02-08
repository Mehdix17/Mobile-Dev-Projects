import csv
import os

source_file = r'c:\Users\mehdi\OneDrive\Bureau\Flutter\cardly\assets\tempo\english_french.csv'
idioms_file = r'c:\Users\mehdi\OneDrive\Bureau\Flutter\cardly\assets\tempo\idioms.csv'

# Specific Part of Speech Dictionaries
conjunctions = {
    "albeit", "although", "and", "as", "because", "but", "for", "if", "lest", "nor", "or", "so", 
    "than", "that", "though", "till", "unless", "until", "when", "whenever", "where", "whereas", 
    "wherever", "whether", "while", "yet"
}

adverbs = {
    "abroad", "ahead", "almost", "already", "altogether", "always", "anyway", "anywhere", "away", 
    "backwards", "badly", "barely", "beforehand", "behind", "below", "beside", "best", "better", 
    "between", "beyond", "both", "briefly", "carefully", "certainly", "clearly", "closely", "commonly", 
    "completely", "constantly", "continually", "daily", "deeply", "definitely", "deliberately", 
    "directly", "early", "easily", "else", "elsewhere", "enough", "especially", "even", "eventually", 
    "ever", "everywhere", "exactly", "extremely", "fairly", "far", "fast", "finally", "forever", 
    "formerly", "forward", "forwards", "frankly", "frequently", "fully", "generally", "gently", 
    "greatly", "hard", "hardly", "heavily", "highly", "honestly", "hopefully", "how", "however", 
    "immediately", "indeed", "independently", "instead", "just", "largely", "late", "lately", 
    "later", "least", "less", "likely", "literally", "little", "loudly", "mainly", "maybe", 
    "meanwhile", "merely", "more", "moreover", "most", "mostly", "much", "naturally", "near", 
    "nearly", "necessarily", "never", "nevertheless", "newly", "normally", "not", "now", "nowhere", 
    "obviously", "occasionally", "off", "often", "once", "only", "openly", "originally", "otherwise", 
    "out", "over", "overnight", "perfectly", "perhaps", "personally", "physically", "possibly", 
    "previously", "probably", "properly", "quickly", "quite", "rarely", "rather", "readily", "really", 
    "recently", "regularly", "relatively", "right", "roughly", "seldom", "seriously", "shortly", 
    "significantly", "similarly", "simply", "slightly", "slowly", "so", "softly", "sometimes", "somewhere", 
    "soon", "specifically", "strongly", "successfully", "suddenly", "surely", "terribly", "then", 
    "there", "therefore", "thus", "together", "too", "totally", "truly", "twice", "typically", 
    "ultimately", "under", "unfortunately", "up", "usually", "very", "voluntarily", "well", "whenever", 
    "where", "wherever", "widely", "wildly", "worse", "wrong", "yet", "hence", "starkly", "steadily", 
    "utterly", "mildly", "seemingly"
}

prepositions = {
    "about", "above", "across", "after", "against", "along", "alongside", "amid", "among", "anti", 
    "around", "as", "at", "before", "behind", "below", "beneath", "beside", "besides", "between", 
    "beyond", "but", "by", "concerning", "considering", "despite", "down", "during", "except", 
    "excepting", "excluding", "following", "for", "from", "in", "inside", "into", "like", "minus", 
    "near", "of", "off", "on", "onto", "opposite", "outside", "over", "past", "per", "plus", 
    "regarding", "round", "save", "since", "than", "through", "to", "toward", "towards", "under", 
    "underneath", "unlike", "until", "up", "upon", "versus", "via", "with", "within", "without"
}

def determine_label(english_text, current_label=""):
    text = english_text.strip().lower()
    words = text.split()
    
    # 1. Check for Idioms/Phrases (Priority if specifically labeled or multi-word structure)
    if current_label == "idiom":
        return "idiom"
    if "?" in text or len(words) >= 3:
        # Check against common non-idiom phrases if necessary, but usually phrases are idioms in this context
        return "idiom"

    # 2. Check for Verbs
    if text.startswith("to ") and len(words) > 1:
        return "verb"

    # 3. Check Exact Matches
    if text in conjunctions:
        return "conjunction"
    if text in adverbs:
        return "adverb"
    if text in prepositions:
        return "preposition"

    # 4. Adjectives (Suffixes and List)
    adj_suffixes = ('able', 'ous', 'ive', 'ful', 'less', 'ic', 'ish', 'ent', 'ant', 'ary', 'ory')
    # Filter out some common noun endings that might clash if needed, but basic rule:
    if len(words) == 1 and text.endswith(adj_suffixes) and text not in ["parent", "student", "moment"]: # minimal exceptions
         return "adjective"
         
    # Expanded adjective list from previous iteration + more
    adj_list = {
        "afraid", "upset", "shady", "stiff", "tight", "thick", "tiny", "tired", "wacky", "versatile", "tough", 
        "thoughtful", "straightforward", "stranded", "sturdy", "soaked", "soggy", "sole", "sleek", "slight", 
        "ruthless", "rusty", "revered", "relevant", "repellent", "rigged", "pissed off", "obnoxious", 
        "old fashioned", "outstanding", "overwhelming", "midday", "misled", "mundane", "loose", "lumpy", 
        "likelihood", "likewise", "jumbled", "confused", "jerky", "ill-humored", "ill-intentioned", "hardened", 
        "harmless", "guilty", "genuinely", "genuine", "freaky", "frightened", "futile", "flabbergasted", 
        "fluffy", "flustered", "forbidden", "former", "exhausted", "disgruntled", "dull", "disgusting", 
        "derelict", "deaf", "daily", "convenient", "comfy", "clumsy", "cheesy", "bruised", "bulletproof", 
        "burgeoning", "barely", "bankrupt", "anxious", "accountable", "ahead", "allegedly", "altogether", "anyway",
        "absent", "ancient", "apparent", "current", "decent", "different", "efficient", "excellent", 
        "frequent", "independent", "innocent", "intelligent", "patient", "present", "recent", "silent", 
        "sufficient", "violent", "angry", "busy", "dirty", "easy", "empty", "funny", "happy", "heavy", 
        "hungry", "lucky", "noisy", "pretty", "ready", "sorry", "ugly", "worthy", "broad", "broader",
        "scared", "squeaky clean", "stainless steel", "difficult", "tense", "fabricated", "wavering", "worse", 
        "seminal", "whimsical", "capricious", "rational", "practical", "technical", "critical", "political", "radical",
        "upbeat"
    }
    if text in adj_list:
        return "adjective"

    # 5. Adverbs (ly suffix) - Be careful with nouns like 'family', 'belly'
    if text.endswith("ly") and text not in ["belly", "family", "jelly", "bully", "rally", "ally", "fly", "apply", "supply", "butterfly", "monopoly", "assembly"]:
        return "adverb"

    return "noun"

# --- Main Logic ---

vocab_rows = []
idiom_rows_to_move = []

# 1. Read Source
with open(source_file, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    fieldnames_source = reader.fieldnames # english, french, frontHint, backHint, label
    
    for row in reader:
        # Determine strict label first
        raw_english = row['english']
        detected_label = determine_label(raw_english, row['label'])
        
        # Override row label with detected one
        row['label'] = detected_label
        
        if detected_label == "idiom":
            idiom_rows_to_move.append(row)
        else:
            vocab_rows.append(row)

# 2. Append to Idioms File
# Read existing to get headers or check empty
file_exists = os.path.isfile(idioms_file)
existing_idioms = []
idiom_fieldnames = ['front', 'back', 'frontHint', 'backHint', 'label']

if file_exists:
    with open(idioms_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        idiom_fieldnames = reader.fieldnames
        for r in reader:
            existing_idioms.append(r)

# Transform source rows to match idiom headers (english->front, french->back)
new_idioms = []
for row in idiom_rows_to_move:
    new_row = {
        'front': row['english'],
        'back': row['french'],
        'frontHint': row['frontHint'],
        'backHint': row['backHint'],
        'label': 'idiom' # Ensure it is labeled idiom
    }
    new_idioms.append(new_row)

# Write Idioms
with open(idioms_file, 'w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=idiom_fieldnames)
    writer.writeheader()
    writer.writerows(existing_idioms + new_idioms)

# 3. Write Updated Source File (Overwrite)
with open(source_file, 'w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames_source)
    writer.writeheader()
    writer.writerows(vocab_rows)

print(f"Moved {len(new_idioms)} idioms to {idioms_file}")
print(f"Updated {source_file} with {len(vocab_rows)} remaining rows and corrected labels.")
