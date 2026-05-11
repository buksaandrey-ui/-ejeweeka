import re
import os

# 1. Update colors.css
colors_file = 'brandbook/tokens/colors.css'
with open(colors_file, 'r') as f:
    colors_content = f.read()

# Change #0D0618 to a slightly brighter but very deep purple so it's not pure black.
colors_content = colors_content.replace('--color-brand-deep-purple:      #0D0618;', '--color-brand-deep-purple:      #2D0A4E;')

with open(colors_file, 'w') as f:
    f.write(colors_content)


# 2. Update page.tsx
page_file = 'landing-page/src/app/page.tsx'
with open(page_file, 'r') as f:
    page_content = f.read()

# Fix opacity in SVGs (Feature & NodeDivider)
page_content = re.sub(r'opacity="0\.[123]"', 'opacity="0.8"', page_content)
page_content = re.sub(r'opacity=\{0\.[123]\}', 'opacity={0.8}', page_content)
page_content = re.sub(r'opacity=\{0\.[456]\}', 'opacity={1}', page_content)
page_content = re.sub(r'opacity="0\.[456]"', 'opacity="1"', page_content)
page_content = re.sub(r'opacity=\[0\.15\]', 'opacity-[0.8]', page_content)

# Fix CTA button
broken_button = r'''<button
            onClick=\{scrollToContent\}
            className=\{`mt-12 px-12 py-4 rounded-full text-lg font-medium transition-all duration-\[2s\] delay-500 hover:bg-white/5 cursor-pointer \$\{heroVisible \? 'opacity-100' : 'opacity-0'\}`\}
            style=\{\{ border: "1px solid var\(--border\)", color: "var\(--text-muted\)" \}\}
          >'''

fixed_button = '''<button
            onClick={scrollToContent}
            className={`mt-12 px-12 py-4 rounded-full text-lg font-bold transition-all duration-[2s] delay-500 cursor-pointer hover:opacity-90 hover:scale-105 ${heroVisible ? 'opacity-100' : 'opacity-0'}`}
            style={{ background: "var(--gradient-neon-mark)", color: "#FFF", border: "none", boxShadow: "0 0 24px rgba(76,29,149,0.5)" }}
          >'''

if re.search(broken_button, page_content):
    page_content = re.sub(broken_button, fixed_button, page_content)
else:
    print("WARNING: Button not found with exact regex. Falling back to simpler replace.")
    # Fallback
    page_content = re.sub(
        r'<button\s*onClick=\{scrollToContent\}\s*className=\{`([^`]*)`\}\s*style=\{\{[^\}]*\}\}\s*>',
        r'<button onClick={scrollToContent} className={`\1 font-bold hover:scale-105`} style={{ background: "var(--gradient-neon-mark)", color: "#FFF", border: "none", boxShadow: "0 0 24px rgba(76,29,149,0.5)" }}>',
        page_content
    )

# Replace the raster image comparison block with native React HTML
comparison_target = r'<Image src="/brand/homepage/comparison.png" alt="ejeweeka vs Calorie Tracker" width=\{800\} height=\{800\} className="w-full" />'

native_comparison = '''<div className="w-full bg-[var(--surface)] border border-[var(--border)] rounded-3xl p-6 md:p-12 shadow-xl">
              <div className="grid grid-cols-3 mb-8 pb-4 border-b border-[var(--border)] font-bold text-sm md:text-xl">
                <div className="col-span-1 text-left text-gray-400">Трекер калорий</div>
                <div className="col-span-1 text-center">Функция</div>
                <div className="col-span-1 text-right text-[var(--primary)] text-2xl font-black">ejeweeka</div>
              </div>
              
              <div className="flex flex-col gap-6 text-sm md:text-base text-[var(--text-main)] font-medium">
                <div className="grid grid-cols-3 items-center">
                  <div className="col-span-1 text-left"><span className="inline-block w-8 h-8 rounded-full border border-[var(--border)]"></span></div>
                  <div className="col-span-1 text-center">Гео/Бюджет адаптация</div>
                  <div className="col-span-1 text-right flex justify-end"><span className="inline-block w-8 h-8 rounded-full" style={{ background: "var(--gradient-neon-mark)", boxShadow: "0 0 12px rgba(76,29,149,0.6)" }}></span></div>
                </div>
                <div className="grid grid-cols-3 items-center">
                  <div className="col-span-1 text-left"><span className="inline-block w-8 h-8 rounded-full border border-[var(--border)]"></span></div>
                  <div className="col-span-1 text-center">Учет витаминов</div>
                  <div className="col-span-1 text-right flex justify-end"><span className="inline-block w-8 h-8 rounded-full" style={{ background: "var(--gradient-neon-mark)", boxShadow: "0 0 12px rgba(76,29,149,0.6)" }}></span></div>
                </div>
                <div className="grid grid-cols-3 items-center">
                  <div className="col-span-1 text-left"><span className="inline-block w-8 h-8 rounded-full border border-[var(--border)]"></span></div>
                  <div className="col-span-1 text-center">Мгновенный пересчет при срыве</div>
                  <div className="col-span-1 text-right flex justify-end"><span className="inline-block w-8 h-8 rounded-full" style={{ background: "var(--gradient-neon-mark)", boxShadow: "0 0 12px rgba(76,29,149,0.6)" }}></span></div>
                </div>
                <div className="grid grid-cols-3 items-center">
                  <div className="col-span-1 text-left"><span className="inline-block w-8 h-8 rounded-full border border-[var(--border)]"></span></div>
                  <div className="col-span-1 text-center">AI Фото-анализ тарелки</div>
                  <div className="col-span-1 text-right flex justify-end"><span className="inline-block w-8 h-8 rounded-full" style={{ background: "var(--gradient-neon-mark)", boxShadow: "0 0 12px rgba(76,29,149,0.6)" }}></span></div>
                </div>
                <div className="grid grid-cols-3 items-center">
                  <div className="col-span-1 text-left"><span className="inline-block w-8 h-8 rounded-full border border-[var(--border)]"></span></div>
                  <div className="col-span-1 text-center">Адаптивные тренировки</div>
                  <div className="col-span-1 text-right flex justify-end"><span className="inline-block w-8 h-8 rounded-full" style={{ background: "var(--gradient-neon-mark)", boxShadow: "0 0 12px rgba(76,29,149,0.6)" }}></span></div>
                </div>
              </div>
            </div>'''

if re.search(comparison_target, page_content):
    page_content = re.sub(comparison_target, native_comparison, page_content)
else:
    print("WARNING: comparison.png not found")

with open(page_file, 'w') as f:
    f.write(page_content)

print("Emergency fixes applied.")
