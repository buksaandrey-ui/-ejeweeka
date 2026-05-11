import re

filepath = 'landing-page/src/app/page.tsx'
with open(filepath, 'r') as f:
    content = f.read()

# The content to inject under the logo in SCREEN 1
hero_injection = """
          <div className="mt-8 text-center">
            <h1 className="text-2xl md:text-4xl font-extrabold leading-tight mb-4" style={{ letterSpacing: "-0.02em" }}>
              Персональный смарт-наставник
              <span className="block" style={{ color: "var(--primary)" }}>по питанию, сну и активности</span>
            </h1>
            <p className="max-w-[600px] mx-auto text-sm md:text-base leading-relaxed mb-8" style={{ color: "var(--text-muted)" }}>
              Алгоритмы на базе доказательной медицины от практикующих врачей. Никаких случайных генераций. Учитывает цель, бюджет, ограничения, витамины и вкусы.
            </p>
          </div>
"""

# Inject into SCREEN 1
# Locate the Image tag in SCREEN 1
image_pattern = r'(<Image\s*src="/brand/ejeweeka-inline-wordmark\.png"\s*alt="ejeweeka — be more · feel alive"[^>]+/>)'
content = re.sub(image_pattern, r'\1' + hero_injection, content)

# Remove SCREEN 2
screen2_pattern = r'\{/\* ── SCREEN 2: Key Message ── \*/\}.*?</section>'
content = re.sub(screen2_pattern, '', content, flags=re.DOTALL)

# Remove NodeDivider after SCREEN 2 (if there's a loose one)
# We can just leave it or remove it if it's there.
content = re.sub(r'<NodeDivider />\s*<NodeDivider />', '<NodeDivider />', content)

with open(filepath, 'w') as f:
    f.write(content)

print("Hero section merged and Screen 2 removed.")
