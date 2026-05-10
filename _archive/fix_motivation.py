import os
import re

texts = {
    "o3-profile.html": "Эти данные — основа всего. Из роста, веса и возраста мы рассчитаем твой базовый обмен веществ: сколько калорий нужно именно твоему телу в состоянии покоя. Обхват талии точнее говорит о висцеральном жире — том, что окружает внутренние органы и реально влияет на здоровье. Именно поэтому мы спрашиваем больше, чем просто «сколько ты весишь». Чем точнее данные — тем точнее вердикт и план.",
    "o14-motivation.html": "У 70% людей главный враг — не еда, а привычки и окружение. Если вечером срываешься на сладкое — это скорее всего не слабая воля, а недоедание днём. Мы учтём твои реальные барьеры и обойдём их. Праздники, стресс, командировки — мы заложим стратегии обхода прямо в план, а не оставим тебя один на один со срывом."
}

css_block = """
    .onboarding-tip-card {
      background-color: #E8F5E9;
      border-radius: 16px;
      padding: 16px;
      display: flex;
      gap: 12px;
      margin-top: auto;
      border: 1px solid #C8E6C9;
    }
    .onboarding-tip-icon {
      font-size: 20px;
      flex-shrink: 0;
    }
    .onboarding-tip-text {
      font-size: 13px;
      color: #2E7D32;
      line-height: 1.5;
      font-weight: 500;
    }
</style>
"""

html_template = """      <!-- Motivation Block -->
      <div class="onboarding-tip-card">
        <div class="onboarding-tip-icon">💡</div>
        <div class="onboarding-tip-text">
          {TEXT}
        </div>
      </div>
    </div>

    <!-- Bottom Actions -->"""

directory = "/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/main-screens/"

# 1. Update the ones I already injected to use the new class names
for filename in os.listdir(directory):
    if not filename.endswith(".html"): continue
    
    filepath = os.path.join(directory, filename)
    with open(filepath, "r") as f:
        content = f.read()

    # If it was injected by my PREVIOUS script, it has ">💡</div>" inside motivation-icon
    if ">💡</div>" in content:
        # replace the injected CSS class names
        content = content.replace(".motivation-card {", ".onboarding-tip-card {")
        content = content.replace(".motivation-icon {", ".onboarding-tip-icon {")
        content = content.replace(".motivation-text {", ".onboarding-tip-text {")
        
        # replace HTML classes for the injected block
        content = content.replace('<div class="motivation-card">\n        <div class="motivation-icon">💡</div>\n        <div class="motivation-text">', '<div class="onboarding-tip-card">\n        <div class="onboarding-tip-icon">💡</div>\n        <div class="onboarding-tip-text">')
        
        with open(filepath, "w") as f:
            f.write(content)

# 2. Inject into the skipped ones (o3 and o14)
for filename, text in texts.items():
    filepath = os.path.join(directory, filename)
    with open(filepath, "r") as f:
        content = f.read()
        
    if "onboarding-tip-card" in content:
        continue # Already there

    # Inject CSS
    content = content.replace("</style>", css_block)

    # Inject HTML
    new_html = html_template.replace("{TEXT}", text)
    content = re.sub(r'</div\s*>\s*<!-- Bottom Actions -->', new_html, content)
    
    with open(filepath, "w") as f:
        f.write(content)
        
print("Fixed and injected.")
