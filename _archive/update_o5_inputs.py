import re

file_path = '/Users/andreybuksa/Downloads/aidiet-docs/05_ui_screens/main-screens/o5-restrictions.html'
with open(file_path, 'r') as f:
    content = f.read()

# Add CSS before </style>
css_injection = """
    .custom-input {
      width: 100%;
      height: 50px;
      margin-top: 12px;
      background: #FFFFFF;
      border: 1px solid var(--color-divider);
      border-radius: 14px;
      padding: 0 16px;
      font-size: 14px;
      color: var(--color-text-primary);
      font-family: inherit;
      outline: none;
      transition: all 0.2s;
    }
    .custom-input::placeholder { color: #9CA3AF; }
    .custom-input:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(245, 146, 43, 0.1); }
"""

if ".custom-input" not in content:
    content = content.replace("</style>", css_injection + "\n</style>")

# Find all chip-grid div ends and append an input right after them.
# The HTML structure is something like:
#      <div class="chip-grid">
#        ...
#      </div>
# We can use regex to find </div> that closes chip-grid. Or simply replace the exact blocks.

# Replace diet chips block
content = content.replace(
    '<div class="chip">Кошерно</div>\n      </div>',
    '<div class="chip">Кошерно</div>\n      </div>\n      <input type="text" class="custom-input" placeholder="Указать другое...">'
)

# Replace allergen chips block
content = content.replace(
    '<div class="chip">Мёд</div>\n      </div>',
    '<div class="chip">Мёд</div>\n      </div>\n      <input type="text" class="custom-input" placeholder="Указать другие аллергены...">'
)

with open(file_path, 'w') as f:
    f.write(content)

print("Inputs added.")
