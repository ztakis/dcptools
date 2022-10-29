# Ask the user to provide a line of text.
# Scan the text for the following mildly offensive words: \
# arse, bloody, damn, dummy.
# If you find any, then replace its letters with asterisks \
# except for the first letter in each offensive word.
# Print the resulting text.

def main():
    text = input("Enter a line of text: ")
    offensive_words = ["arse", "bloody", "damn", "dummy"]
    for word in offensive_words:
        if word in text:
            text = text.replace(word, word[0] + "*" * (len(word) - 1))
            print(word[0])
    print(text)

main()