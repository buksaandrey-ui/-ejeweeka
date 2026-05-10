import re
import shutil

html_file = '/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/main-screens/h1-dashboard.html'

# Step 3 part A: Backup
shutil.copy(html_file, html_file.replace('.html', '.backup.html'))

with open(html_file, 'r') as f:
    content = f.read()

# Step 3 part B: Add CSS
css_to_add = """
    @keyframes greetingFadeIn {
      from { opacity: 0; transform: translateY(-6px); }
      to   { opacity: 1; transform: translateY(0);    }
    }
    .greeting-block {
      padding: 24px 20px 8px;
      min-height: 72px;
      animation: greetingFadeIn 0.4s ease forwards;
    }
    .greeting-line1 {
      font-size: 14px;
      color: var(--color-text-secondary);
      margin: 0 0 4px;
      letter-spacing: 0.2px;
      line-height: 1.4;
    }
    .greeting-line2 {
      font-size: 26px;
      font-weight: 700;
      color: var(--color-text-primary);
      margin: 0;
      line-height: 1.25;
      letter-spacing: -0.3px;
    }
"""
if ".greeting-block {" not in content:
    content = content.replace("  </style>", css_to_add + "  </style>")

# Step 3 part C: Replace Header with Greeting Block
greeting_html = """      <div class="greeting-block" id="greetingBlock">
        <p class="greeting-line1" id="greetingLine1"></p>
        <h1 class="greeting-line2" id="greetingLine2"></h1>
      </div>"""

# Replace the old header entirely
header_pattern = re.compile(r'<header class="app-header">.*?</header>', re.DOTALL)
content = header_pattern.sub(greeting_html, content)

# Step 3 part D: Inject JS and Dev Button before </body>
js_to_add = """
  <!-- DEV ONLY: тест смены имени -->
  <div id="devNameTest" style="position:fixed;bottom:100px;right:16px;
       background:rgba(255,107,53,0.15);border:1px solid #FF6B35;
       border-radius:12px;padding:12px;font-size:12px;color:#000;z-index:999;backdrop-filter:blur(4px);">
    <input id="devNameInput" placeholder="Введи имя" maxlength="20"
           style="background:transparent;border:none;color:#000;
                  outline:none;width:120px;">
    <button onclick="
      localStorage.setItem('user_nickname', document.getElementById('devNameInput').value);
      window.dispatchEvent(new Event('user_profile_updated'));
    " style="background:#FF6B35;border:none;border-radius:8px;
             color:#fff;padding:4px 10px;cursor:pointer;margin-left:8px;">
      Применить
    </button>
  </div>

  <script type="module">
    import { getGreeting } from './h1-greeting-engine.js';

    const mockProfile = {
      nickname: localStorage.getItem('user_nickname') || '',
      gender: localStorage.getItem('user_gender') || 'female',
      birth_year: parseInt(localStorage.getItem('user_birth_year')) || 1990,
      goal: localStorage.getItem('user_goal') || 'weight_loss',
      progress_percent: parseFloat(localStorage.getItem('user_progress')) || 40,
      workout_done_today: localStorage.getItem('workout_done_today') === 'true',
      last_greeting_epithet: localStorage.getItem('last_greeting_epithet') || ''
    };

    function renderGreeting() {
      const greeting = getGreeting(mockProfile);
      document.getElementById('greetingLine1').textContent = greeting.line1;
      document.getElementById('greetingLine2').textContent = greeting.line2;
    }

    renderGreeting();

    window.addEventListener('user_profile_updated', () => {
      mockProfile.nickname = localStorage.getItem('user_nickname') || '';
      renderGreeting();
    });

    setInterval(() => {
      renderGreeting();
    }, 60 * 1000);
  </script>
</body>"""

if "import { getGreeting }" not in content:
    content = content.replace("</body>", js_to_add)

with open(html_file, 'w') as f:
    f.write(content)

# Step 4: Update Documentation files
map_file = '/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/screens-map.md'
with open(map_file, 'r') as f:
    map_content = f.read()

dashboard_append = """
  * **Dynamic Greeting System**: A personalized 2-line greeting reflecting user details.
    * Input parameters: nickname, gender, birth_year, goal, progress_percent, workout_done_today
    * Implementation files:
      - `h1-greeting-data.json`
      - `h1-greeting-engine.js`"""

if "Dynamic Greeting System" not in map_content:
    map_content = map_content.replace("- PR-1: Отображает график изменения веса.", "- PR-1: Отображает график изменения веса." + dashboard_append)
    with open(map_file, 'w') as f:
        f.write(map_content)

context_file = '/Users/andreybuksa/Downloads/aidiet-docs/PROJECT_CONTEXT.md'
with open(context_file, 'r') as f:
    ctx_content = f.read()

if "Дашборд содержит динамическое приветствие" not in ctx_content:
    ctx_content = ctx_content.replace(
        "H-1 Dashboard: Главный экран", 
        "H-1 Dashboard: Главный экран. Дашборд содержит динамическое приветствие, персонализированное по полу, возрасту, цели, времени суток и прогрессу."
    )
    with open(context_file, 'w') as f:
        f.write(ctx_content)

print("Steps 3 and 4 completed successfully.")
