import glob
import json
import re


def extract_from_json(file_path):
    with open(file_path, encoding="utf-8") as f:
        data = json.load(f)

    chars = set()
    if isinstance(data, list):
        for item in data:
            for key in ["question", "answer"]:
                if key in item:
                    chars.update(item[key])
            if "distractors" in item:
                for d in item["distractors"]:
                    chars.update(d)
            if "alternative_answers" in item:
                for a in item["alternative_answers"]:
                    chars.update(a)
    return chars


def extract_from_tscn(file_path):
    with open(file_path, encoding="utf-8") as f:
        content = f.read()

    # Extract text = "..."
    matches = re.findall(r'text\s*=\s*"([^"]*)"', content)
    chars = set()
    for m in matches:
        # Handle escaped characters if any (simplified)
        chars.update(m.replace("\\n", "\n").replace('\\"', '"'))
    return chars


def main():
    all_chars = set()

    # Static UI characters
    static_text = (
        "TRIVIA DASH"
        "Answer fast. Stay alive."
        "QUICK PLAY"
        "ENDLESS PLAY"
        "High Score: 0123456789"
        "Score: "
        "30.0"
        "GAME OVER"
        "NEW HIGH SCORE!"
        "PLAY AGAIN"
        "MAIN MENU"
        "Error: No questions found!"
        "★✗🎉⭐✨💥🔥✓+"
        "Build: Dev.0123456789-TZ:"  # For date/time
        "|/\\"  # Spacers or other symbols
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        "0123456789.,!?:;()'- \"&"
    )
    all_chars.update(static_text)

    # From questions
    for json_file in glob.glob("data/questions/*.json"):
        if "categories.json" in json_file:
            # Maybe categories too?
            with open(json_file, encoding="utf-8") as f:
                cats = json.load(f)
                for cat in cats:
                    all_chars.update(cat.get("name", ""))
                    all_chars.update(cat.get("description", ""))
            continue
        all_chars.update(extract_from_json(json_file))

    # From TSCN
    all_chars.update(extract_from_tscn("scenes/main.tscn"))

    # Sort and output
    sorted_chars = sorted(list(all_chars))
    print("".join(sorted_chars))


if __name__ == "__main__":
    main()
