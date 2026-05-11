import re

with open("landing/index.html", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update CSS Variables for Dark Mode
css_vars_old = """        :root {
            --primary: #F5922B;
            --primary-hover: #E8831A;
            --green: #52B044;
            --orange: #F09030;
            --blue: #42A5F5;
            --bg: #FAFAFA;
            
            --deep-text: #111111;
            --secondary-text: rgba(17, 17, 17, 0.68);
            --muted-text: rgba(17, 17, 17, 0.48);
            
            --card-bg: #FFFFFF;
            --soft-border: rgba(17, 17, 17, 0.08);
            
            --premium-shadow: 0 24px 80px rgba(17, 17, 17, 0.08);
            --soft-orange-glow: 0 24px 90px rgba(245, 146, 43, 0.22);
            --glass-layer: rgba(255, 255, 255, 0.72);"""

css_vars_new = """        :root {
            --primary: #F5922B;
            --primary-hover: #E8831A;
            --green: #52B044;
            --orange: #F09030;
            --blue: #42A5F5;
            --bg: #000000;
            
            --deep-text: #FFFFFF;
            --secondary-text: rgba(255, 255, 255, 0.68);
            --muted-text: rgba(255, 255, 255, 0.48);
            
            --card-bg: #0A0A0A;
            --soft-border: rgba(255, 255, 255, 0.08);
            
            --premium-shadow: 0 24px 80px rgba(0, 0, 0, 0.4);
            --soft-orange-glow: 0 0 50px rgba(245, 146, 43, 0.25);
            --glass-layer: rgba(17, 17, 17, 0.72);"""

content = content.replace(css_vars_old, css_vars_new)

# 2. Update gradient-text to have drop shadow
content = content.replace(
    """        .gradient-text {
            background: linear-gradient(135deg, var(--primary), #FFB15E);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }""",
    """        .gradient-text {
            background: linear-gradient(135deg, #F5922B, #FFB15E);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            text-shadow: 0 0 30px rgba(245, 146, 43, 0.3);
        }"""
)

# 3. Update btn-primary and nav
content = content.replace(
    """        .btn-primary {
            background: var(--primary); color: #fff;
            box-shadow: var(--soft-orange-glow);
        }
        .btn-primary:hover {
            background: var(--primary-hover); transform: translateY(-2px);
            box-shadow: 0 30px 100px rgba(245, 146, 43, 0.3);
        }""",
    """        .btn-primary {
            background: linear-gradient(135deg, #F5922B, #E8831A); color: #fff;
            box-shadow: 0 0 30px rgba(245, 146, 43, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 0 50px rgba(245, 146, 43, 0.5);
        }"""
)

content = content.replace(
    """background: rgba(250, 250, 250, 0.75);""",
    """background: rgba(0, 0, 0, 0.75);"""
)

# 4. Hero section replacement
hero_old = """    <!-- HERO -->
    <section class="hero">
        <div class="hero-glow"></div>
        <div class="container hero-grid">
            <div class="hero-text">
                <div class="badge reveal">Health Code App</div>
                <h1 class="reveal stagger-1">Ваш персональный <br><span class="gradient-text">код питания, сна</span> и активности</h1>
                <p class="reveal stagger-2" style="font-size: 1.25rem; margin-bottom: 2.5rem;">Health Code собирает ваши цели, режим, ограничения, бюджет и любимые продукты в один понятный план: что есть, что купить, когда принимать добавки и как корректировать день без срывов.</p>
                
                <div class="btn-group reveal stagger-3">
                    <a href="#pricing" class="btn btn-primary">Попробовать Gold на 3 дня</a>
                    <a href="#pricing" class="btn btn-secondary">Посмотреть статусы</a>
                </div>

                <div class="trust-row reveal stagger-4">
                    <div class="trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 6L9 17l-5-5"></path></svg>
                        3 дня Gold-доступа
                    </div>
                    <div class="trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 6L9 17l-5-5"></path></svg>
                        Фото-анализ еды
                    </div>
                    <div class="trust-item">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M20 6L9 17l-5-5"></path></svg>
                        Данные на устройстве
                    </div>
                </div>

                <div class="microtext reveal stagger-4">
                    Wellness-рекомендации. Не диагностика и не лечение. Данные профиля хранятся на устройстве.
                </div>
            </div>
            
            <div class="hero-visual reveal stagger-2" id="hero-parallax">
                <div class="mockup-stack">
                    <div class="iphone-17-pro mockup-back">
                        <div class="glass-reflection"></div>
                        <div class="screen"><img src="assets/screens/p1-weekly-plan.webp" alt="План питания"></div>
                    </div>
                    <div class="iphone-17-pro mockup-front">
                        <div class="glass-reflection"></div>
                        <div class="screen"><img src="assets/screens/h1-dashboard.webp" alt="Дашборд Health Code"></div>
                    </div>
                </div>
            </div>
        </div>
    </section>"""

hero_new = """    <!-- HERO -->
    <section class="hero" style="flex-direction: column; justify-content: center; text-align: center; padding-top: 10rem;">
        <div class="hero-glow" style="top: 20%; left: 50%; transform: translate(-50%, -50%);"></div>
        <div class="container hero-text" style="max-width: 800px; margin: 0 auto;">
            <h1 class="reveal stagger-1">Архитектура вашего тела.<br><span class="gradient-text">Идеально рассчитана.</span></h1>
            <p class="reveal stagger-2" style="font-size: 1.125rem; margin-bottom: 2.5rem; max-width: 700px; margin-left: auto; margin-right: auto;">Ваша энергия, продуктивность и физическая форма больше не зависят от случайностей. Health Code объединяет питание, восстановление, тренировки и графики добавок в единый смарт-план.</p>
            
            <div class="btn-group reveal stagger-3" style="justify-content: center;">
                <a href="#pricing" class="btn btn-primary" style="padding: 18px 48px; border-radius: 100px; font-size: 1.1rem;">Активировать Status Gold</a>
            </div>

            <div class="microtext reveal stagger-4" style="margin-top: 24px; margin-left: auto; margin-right: auto;">
                Управление доступом через приватного Telegram-консьержа
            </div>
        </div>
        
        <div class="hero-visual reveal stagger-2" id="hero-parallax" style="margin-top: 4rem; height: auto;">
            <div class="iphone-17-pro" style="margin: 0 auto; box-shadow: 0 -20px 80px rgba(245,146,43,0.15);">
                <div class="glass-reflection"></div>
                <div class="screen"><img src="assets/screens/h1-dashboard.webp" alt="Дашборд Health Code"></div>
            </div>
        </div>
    </section>"""

content = content.replace(hero_old, hero_new)

# 5. Nav bar fixes (Скачать instead of Статусы)
content = content.replace(
    """<a href="#pricing" class="btn btn-primary" style="padding: 10px 24px; font-size: 0.95rem;">Статусы</a>""",
    """<a href="#download" class="btn btn-primary" style="padding: 10px 24px; font-size: 0.95rem;">Скачать</a>"""
)

# 6. Change hardcoded #FFFFFF backgrounds to var(--bg) or var(--card-bg)
content = content.replace("""background: #FFFFFF;""", """background: var(--bg);""")
content = content.replace("""background: #FFFFFF;""", """background: var(--bg);""")

content = content.replace(
    """        .pricing-section { background: #FFFFFF; border-top: 1px solid var(--soft-border); border-bottom: 1px solid var(--soft-border); position: relative; }""",
    """        .pricing-section { background: var(--bg); border-top: 1px solid var(--soft-border); border-bottom: 1px solid var(--soft-border); position: relative; }"""
)
content = content.replace(
    """        .pricing-card:hover { transform: translateY(-4px); box-shadow: var(--premium-shadow); background: #fff;}""",
    """        .pricing-card:hover { transform: translateY(-4px); box-shadow: var(--premium-shadow); background: var(--card-bg);}"""
)
content = content.replace(
    """        .pricing-card.gold {
            background: #fff; border: 2px solid var(--primary);""",
    """        .pricing-card.gold {
            background: var(--card-bg); border: 2px solid var(--primary);"""
)

content = content.replace(
    """        .feature-card:hover {
            background: #fff; transform: translateY(-4px); box-shadow: var(--premium-shadow); border-color: rgba(245, 146, 43, 0.3);
        }""",
    """        .feature-card:hover {
            background: var(--card-bg); transform: translateY(-4px); box-shadow: var(--premium-shadow); border-color: rgba(245, 146, 43, 0.3);
        }"""
)

content = content.replace(
    """        footer {
            background: #FFFFFF; border-top: 1px solid var(--soft-border);""",
    """        footer {
            background: var(--bg); border-top: 1px solid var(--soft-border);"""
)

# 7. Fix JS scrolling nav background
content = content.replace(
    """navbar.style.background = 'rgba(250, 250, 250, 0.85)';""",
    """navbar.style.background = 'rgba(10, 10, 10, 0.85)';"""
)
content = content.replace(
    """navbar.style.background = 'rgba(250, 250, 250, 0.5)';""",
    """navbar.style.background = 'rgba(10, 10, 10, 0.5)';"""
)

with open("landing/index.html", "w", encoding="utf-8") as f:
    f.write(content)

print("HTML successfully patched to Premium Dark Mode.")
