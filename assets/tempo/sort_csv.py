import csv
import operator

file_path = r'c:\Users\mehdi\OneDrive\Bureau\Flutter\cardly\assets\tempo\english_french.csv'

# Read the CSV
with open(file_path, 'r', encoding='utf-8', newline='') as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    rows = list(reader)

# Sort the rows by 'front' column, case-insensitive
rows.sort(key=lambda row: row['front'].lower())

# Write the CSV back
with open(file_path, 'w', encoding='utf-8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print(f"Sorted {len(rows)} rows in {file_path} by 'front' column.")
