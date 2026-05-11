import os, re

def replace_in_dir(path):
    count = 0
    pattern_title = re.compile(r"<title>AIDiet")
    pattern_alt = re.compile(r"alt=\"AIDiet\"")
    pattern_shopping1 = re.compile(r"Мой список покупок \(AIDiet\)")
    pattern_shopping2 = re.compile(r"title:\s*'\s*AIDiet\s*—\s*Покупки\s*'")
    pattern_intel = re.compile(r"Интеллект AIDiet")
    pattern_welcome = re.compile(r"<h1>AIDiet -")
    
    for root, dirs, files in os.walk(path):
        for f in files:
            if f.endswith((".html", ".js", ".py", ".md", ".json")):
                file_path = os.path.join(root, f)
                with open(file_path, "r", encoding="utf-8") as file:
                    content = file.read()
                    
                orig = content
                content = pattern_title.sub("<title>Health Code", content)
                content = pattern_alt.sub('alt="Health Code"', content)
                content = pattern_shopping1.sub("Мой список покупок (Health Code)", content)
                content = pattern_shopping2.sub("title: 'Health Code — Покупки'", content)
                content = pattern_intel.sub("Интеллект Health Code", content)
                content = pattern_welcome.sub("<h1>Health Code -", content)
                
                # General replacement for text occurrences.
                # Avoid window.AIDiet, aidiet_profile, etc.
                # Safe regex: Not preceded by a word char, dot, or dash. Not followed by a word char, dot, or dash.
                content = re.sub(r"(?<![a-zA-Z0-9_.-])AIDiet(?![a-zA-Z0-9_.-])", "Health Code", content)
                
                if orig != content:
                    with open(file_path, "w", encoding="utf-8") as file:
                        file.write(content)
                    count += 1
                    print(f"Updated {f}")
    return count

print("Main Screens:", replace_in_dir("/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/main-screens/"))
print("Core Engine:", replace_in_dir("/Users/andreybuksa/Downloads/aidiet-docs/03_core_engine/"))
print("App MVC:", replace_in_dir("/Users/andreybuksa/Downloads/aidiet-docs/app_mvc/"))
