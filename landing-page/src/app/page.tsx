"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";
import Link from "next/link";

/* ── Connected-Node SVG decorators (brand pattern) ── */
const NodeDivider = () => (
  <div className="flex items-center justify-center gap-2 py-12 opacity-[0.6]">
    <svg width="8" height="8"><circle cx="4" cy="4" r="3" fill="var(--primary)"/></svg>
    <svg width="40" height="2"><line x1="0" y1="1" x2="40" y2="1" stroke="var(--primary)" strokeWidth="1"/></svg>
    <svg width="12" height="12"><circle cx="6" cy="6" r="5" fill="var(--primary)"/></svg>
    <svg width="40" height="2"><line x1="0" y1="1" x2="40" y2="1" stroke="var(--primary)" strokeWidth="1"/></svg>
    <svg width="6" height="6"><circle cx="3" cy="3" r="2.5" fill="var(--primary)"/></svg>
    <svg width="40" height="2"><line x1="0" y1="1" x2="40" y2="1" stroke="var(--primary)" strokeWidth="1"/></svg>
    <svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="var(--primary)"/></svg>
  </div>
);

/* ── Feature SVG illustrations (unique per feature) ── */
const featureSVGs: Record<string, React.ReactNode> = {
  params: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      {[{x:60,y:20,r:5},{x:30,y:40,r:4},{x:90,y:35,r:4},{x:20,y:70,r:3},{x:50,y:55,r:5},{x:80,y:60,r:4},{x:40,y:85,r:3},{x:70,y:80,r:4},{x:100,y:75,r:3},{x:15,y:50,r:3},{x:105,y:50,r:3},{x:60,y:100,r:4}].map((n,i) => (
        <React.Fragment key={i}>
          <circle cx={n.x} cy={n.y} r={n.r} fill="var(--primary)" opacity={[0.9, 0.6, 0.7, 0.75, 0.85, 0.5, 0.8, 0.6, 0.9, 0.45, 0.35, 0.85][i]}/>
          {i > 0 && <line x1={n.x} y1={n.y} x2={[{x:60,y:20},{x:30,y:40},{x:90,y:35},{x:20,y:70},{x:50,y:55},{x:80,y:60},{x:40,y:85},{x:70,y:80},{x:100,y:75},{x:15,y:50},{x:105,y:50},{x:60,y:100}][(i-1)].x} y2={[{x:60,y:20},{x:30,y:40},{x:90,y:35},{x:20,y:70},{x:50,y:55},{x:80,y:60},{x:40,y:85},{x:70,y:80},{x:100,y:75},{x:15,y:50},{x:105,y:50},{x:60,y:100}][(i-1)].y} stroke="var(--primary)" strokeWidth="0.5" opacity="0.8"/>}
        </React.Fragment>
      ))}
    </svg>
  ),
  photo: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <rect x="30" y="25" width="60" height="75" rx="8" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="1"/>
      <circle cx="60" cy="55" r="15" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="60" cy="55" r="6" fill="var(--primary)" opacity="1"/>
      {[{x1:80,y1:55,x2:90,y2:55},{x1:70,y1:72.3,x2:75,y2:80.9},{x1:50,y1:72.3,x2:45,y2:80.9},{x1:40,y1:55,x2:30,y2:55},{x1:50,y1:37.7,x2:45,y2:29.1},{x1:70,y1:37.7,x2:75,y2:29.1}].map((l,i) => <line key={i} x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2} stroke="var(--primary)" strokeWidth="0.8" opacity="0.8"/>)}
    </svg>
  ),
  vitamins: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <circle cx="35" cy="40" r="12" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="85" cy="40" r="12" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="60" cy="85" r="12" fill="none" stroke="#52B044" strokeWidth="1.5" opacity="0.8"/>
      <line x1="47" y1="40" x2="73" y2="40" stroke="#FF4444" strokeWidth="1" opacity="1" strokeDasharray="4 2"/>
      <line x1="35" y1="52" x2="52" y2="77" stroke="#52B044" strokeWidth="1" opacity="1"/>
      <line x1="85" y1="52" x2="68" y2="77" stroke="#52B044" strokeWidth="1" opacity="1"/>
      <text x="35" y="44" textAnchor="middle" fill="var(--primary)" fontSize="8" fontWeight="bold">Fe</text>
      <text x="85" y="44" textAnchor="middle" fill="var(--primary)" fontSize="8" fontWeight="bold">Ca</text>
      <text x="60" y="89" textAnchor="middle" fill="#52B044" fontSize="8" fontWeight="bold">D3</text>
    </svg>
  ),
  geo: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      {[{x:30,y:30},{x:70,y:25},{x:100,y:45},{x:20,y:60},{x:55,y:55},{x:85,y:70},{x:35,y:90},{x:75,y:90}].map((p,i) => <circle key={i} cx={p.x} cy={p.y} r="3" fill="var(--primary)" opacity="0.8"/>)}
      <circle cx="55" cy="55" r="8" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.9"/>
      <circle cx="55" cy="55" r="3" fill="var(--primary)" opacity="0.8"/>
      <circle cx="55" cy="55" r="18" fill="none" stroke="var(--primary)" strokeWidth="0.5" opacity="0.8"/>
      <circle cx="55" cy="55" r="30" fill="none" stroke="var(--primary)" strokeWidth="0.3" opacity="0.8"/>
    </svg>
  ),
  recalc: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <polyline points="10,80 30,75 50,70 60,85 70,50 90,45 110,40" fill="none" stroke="var(--border)" strokeWidth="1.5" strokeDasharray="3 2"/>
      <polyline points="10,80 30,75 50,70 60,55 70,50 90,45 110,40" fill="none" stroke="var(--primary)" strokeWidth="1.5"/>
      <circle cx="60" cy="85" r="4" fill="var(--border)"/>
      <circle cx="60" cy="55" r="4" fill="var(--primary)"/>
      <line x1="60" y1="82" x2="60" y2="58" stroke="var(--primary)" strokeWidth="0.8" opacity="1" strokeDasharray="2 1"/>
    </svg>
  ),
  shopping: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <circle cx="60" cy="60" r="35" fill="none" stroke="var(--primary)" strokeWidth="0.5" opacity="0.8"/>
      <circle cx="45" cy="45" r="15" fill="var(--primary)" opacity="0.8" stroke="var(--primary)" strokeWidth="0.8"/>
      <circle cx="75" cy="50" r="12" fill="var(--primary)" opacity="0.8" stroke="var(--primary)" strokeWidth="0.8"/>
      <circle cx="55" cy="75" r="13" fill="var(--primary)" opacity="0.8" stroke="var(--primary)" strokeWidth="0.8"/>
      <circle cx="45" cy="45" r="3" fill="var(--primary)" opacity="1"/><circle cx="75" cy="50" r="3" fill="var(--primary)" opacity="1"/><circle cx="55" cy="75" r="3" fill="var(--primary)" opacity="1"/>
    </svg>
  ),
  privacy: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <path d="M60 20 L95 40 L95 70 Q95 100 60 110 Q25 100 25 70 L25 40 Z" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="1"/>
      <rect x="50" y="55" width="20" height="16" rx="3" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.8"/>
      <path d="M54 55 L54 48 Q54 42 60 42 Q66 42 66 48 L66 55" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="60" cy="63" r="2" fill="var(--primary)"/>
    </svg>
  ),
  fasting: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <circle cx="60" cy="60" r="40" fill="none" stroke="var(--border-accent)" strokeWidth="1.5"/>
      <path d="M60 20 A40 40 0 0 1 97 73" fill="none" stroke="var(--primary)" strokeWidth="4" opacity="0.8" strokeLinecap="round"/>
      <path d="M97 73 A40 40 0 0 1 23 73" fill="none" stroke="var(--border-accent)" strokeWidth="4" strokeLinecap="round"/>
      <path d="M23 73 A40 40 0 0 1 60 20" fill="none" stroke="var(--border-accent)" strokeWidth="4" strokeLinecap="round"/>
      <circle cx="60" cy="60" r="2" fill="var(--primary)"/>
      <text x="60" y="56" textAnchor="middle" fill="var(--text-muted)" fontSize="7">16:8</text>
    </svg>
  ),
  recipes: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      {/* 3 recipe cards stacked */}
      <rect x="20" y="15" width="35" height="50" rx="6" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.6"/>
      <rect x="42" y="25" width="35" height="50" rx="6" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.8"/>
      <rect x="64" y="35" width="35" height="50" rx="6" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="1"/>
      {/* Checkmarks */}
      <path d="M72 50 L77 55 L87 45" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round"/>
      <path d="M72 62 L77 67 L87 57" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" opacity="0.5"/>
      {/* Lines = ingredients */}
      <line x1="30" y1="30" x2="46" y2="30" stroke="var(--primary)" strokeWidth="1" opacity="0.4"/>
      <line x1="30" y1="37" x2="42" y2="37" stroke="var(--primary)" strokeWidth="1" opacity="0.3"/>
      <text x="60" y="105" textAnchor="middle" fill="var(--text-muted)" fontSize="7" fontWeight="bold">×3</text>
    </svg>
  ),
  workouts: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      {/* Dumbbell */}
      <rect x="25" y="50" width="15" height="20" rx="3" fill="none" stroke="var(--primary)" strokeWidth="1.5"/>
      <rect x="80" y="50" width="15" height="20" rx="3" fill="none" stroke="var(--primary)" strokeWidth="1.5"/>
      <line x1="40" y1="60" x2="80" y2="60" stroke="var(--primary)" strokeWidth="2.5"/>
      {/* Pulse line */}
      <polyline points="15,30 35,30 42,15 50,45 58,25 65,35 72,30 105,30" fill="none" stroke="var(--primary)" strokeWidth="1.5" opacity="0.7" strokeLinecap="round"/>
      {/* Energy bolt */}
      <path d="M57 80 L63 90 L58 90 L62 102" fill="none" stroke="var(--primary)" strokeWidth="1.5" strokeLinecap="round" opacity="0.8"/>
    </svg>
  ),
};

const features = [
  { key: "params", title: "60+ параметров", desc: "Город, бюджет, аллергии, тренировки, голодание, микробиом — всё влияет на план", large: true },
  { key: "photo", title: "AI-фото анализ", desc: "Сфотографируй тарелку — нейросеть пересчитает план за секунду", large: true },
  { key: "vitamins", title: "Совместимость витаминов", desc: "Железо ≠ кофе, D₃ + жиры, магний на ночь — автоматически" },
  { key: "geo", title: "Гео-адаптация рациона", desc: "План учитывает страну, город, продукты и бюджет" },
  { key: "recalc", title: "Мгновенная коррекция", desc: "Съел не по плану — ужин и тренировка пересчитаны" },
  { key: "shopping", title: "Умный список покупок", desc: "Продукты группируются под рецепты и план" },
  { key: "privacy", title: "Zero-Knowledge", desc: "Чувствительные данные не покидают устройство" },
  { key: "fasting", title: "Интервальное голодание", desc: "IF-окно встроено в план: еда, витамины и тренировки синхронизированы" },
  { key: "recipes", title: "Пошаговые рецепты", desc: "3 варианта каждого блюда с ингредиентами, граммовками и чек-листом приготовления" },
  { key: "workouts", title: "Адаптивные тренировки", desc: "Персональные видео-тренировки, подстроенные под твою энергию, цели и оборудование" },
];

/* ── Reveal on scroll hook ── */
function useReveal() {
  const ref = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(([e]) => { if (e.isIntersecting) { setVisible(true); obs.disconnect(); }}, { threshold: 0.15 });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);
  return { ref, visible };
}

const RevealSection = ({ children, className = "" }: { children: React.ReactNode; className?: string }) => {
  const { ref, visible } = useReveal();
  return <div ref={ref} className={`transition-all duration-[1s] ease-out ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'} ${className}`}>{children}</div>;
};

export default function HomePage() {
  const [heroVisible, setHeroVisible] = useState(false);
  const [showNav, setShowNav] = useState(false);

  useEffect(() => {
    setTimeout(() => setHeroVisible(true), 200);
    const onScroll = () => setShowNav(window.scrollY > window.innerHeight * 0.8);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const scrollToContent = () => window.scrollTo({ top: window.innerHeight, behavior: "smooth" });

  return (
    <div className="min-h-screen" style={{ background: "var(--bg)", color: "var(--text-main)" }}>

      {/* ── Sticky Nav (appears on scroll) ── */}
      <nav
        className="fixed top-0 left-0 right-0 z-50 transition-all duration-300"
        style={{
          transform: showNav ? "translateY(0)" : "translateY(-100%)",
          background: "rgba(249,250,251,0.92)",
          backdropFilter: "blur(24px)",
          WebkitBackdropFilter: "blur(24px)",
          borderBottom: "1px solid var(--border)",
        }}
      >
        <div className="max-w-[1200px] mx-auto flex justify-between items-center h-16 px-6">
          <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={160} height={50} priority style={{ height: 'auto' }} />
          <div className="flex items-center gap-6">
            <a href="#features" className="text-sm hover:text-[var(--text-main)] transition-colors" style={{ color: "var(--text-muted)" }}>О продукте</a>
            <Link href="/subscribe" className="text-sm font-semibold transition-colors" style={{ color: "var(--primary)" }}>Начать</Link>
          </div>
        </div>
      </nav>

      {/* ── SCREEN 1: Hero (100vh) ── */}
      <section className="min-h-screen flex flex-col items-center justify-center px-6 relative overflow-hidden" style={{ background: "var(--bg)" }}>
        {/* Subtle light spots — like a textured wall */}
        <div className="absolute top-[20%] left-[15%] w-[500px] h-[500px] rounded-full opacity-[0.06]" style={{ background: "radial-gradient(circle, var(--text-muted), transparent 60%)" }} />
        <div className="absolute top-[60%] right-[10%] w-[400px] h-[400px] rounded-full opacity-[0.04]" style={{ background: "radial-gradient(circle, rgba(255,255,255,0.3), transparent 60%)" }} />
        <div className="absolute top-[10%] right-[30%] w-[300px] h-[300px] rounded-full opacity-[0.03]" style={{ background: "radial-gradient(circle, rgba(76,29,149,0.3), transparent 60%)" }} />

        <div className={`relative z-10 flex flex-col items-center transition-all duration-[2s] ease-out ${heroVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
          <Image
            src="/brand/ejeweeka-inline-wordmark.png"
            alt="ejeweeka — be more · feel alive"
            width={853}
            height={268}
            priority
            style={{ maxWidth: "min(600px, 80vw)", height: "auto" }}
          />
          <div className="mt-8 text-center">
            <h1 className="text-2xl md:text-4xl font-extrabold leading-tight mb-4 text-[var(--text-main)]" style={{ letterSpacing: "-0.02em" }}>
              Персональный смарт-наставник
              <span className="block" style={{ color: "var(--primary)" }}>по питанию, сну и активности</span>
            </h1>
            <p className="max-w-[640px] mx-auto text-sm md:text-base leading-relaxed mb-8" style={{ color: "var(--text-muted)" }}>
              Умные алгоритмы на базе 16 000+ материалов от практикующих экспертов, кандидатов и докторов наук. Никаких случайных и мусорных генераций и общих диет. Учитываем цель, бюджет, регион, ограничения, витамины и вкусы.
            </p>
          </div>

          <button
            onClick={scrollToContent}
            className={`mt-12 px-12 py-4 rounded-full text-lg font-bold transition-all duration-[2s] delay-500 cursor-pointer hover:opacity-90 hover:scale-105 ${heroVisible ? 'opacity-100' : 'opacity-0'}`}
            style={{ background: "var(--gradient-neon-mark)", color: "#FFF", border: "none", boxShadow: "0 0 24px rgba(76,29,149,0.5)" }}
          >
            Начать
          </button>
        </div>
      </section>

      

      <NodeDivider />

      {/* ── SCREEN 3: 8 Killer Features ── */}
      <section id="features" className="py-24 px-6">
        <RevealSection>
          <div className="max-w-[1200px] mx-auto">
            <p className="text-center text-sm tracking-[0.25em] uppercase font-medium mb-4" style={{ color: "var(--primary)" }}>Уникальные возможности</p>
            <h2 className="text-center text-3xl md:text-4xl font-bold mb-16 text-[var(--text-main)]" style={{ letterSpacing: "-0.02em" }}>Чего нет ни у кого</h2>

            {/* Bento grid: 2 large + 6 small */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {features.map((f, i) => (
                <div
                  key={f.key}
                  className={`group rounded-2xl p-6 transition-all duration-300 hover:scale-[1.01] ${f.large ? 'lg:col-span-2 lg:row-span-2' : ''}`}
                  style={{
                    background: "rgba(139,92,246,0.04)",
                    border: "1px solid rgba(139,92,246,0.08)",
                    borderRadius: "16px",
                  }}
                >
                  <div className={`${f.large ? 'w-32 h-32 md:w-40 md:h-40' : 'w-16 h-16'} mx-auto mb-4 transition-transform duration-300 group-hover:scale-110`}>
                    {featureSVGs[f.key]}
                  </div>
                  <h3 className={`font-bold text-[var(--text-main)] mb-2 ${f.large ? 'text-xl' : 'text-base'}`}>{f.title}</h3>
                  <p className="text-sm leading-relaxed" style={{ color: "var(--text-muted)" }}>{f.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </RevealSection>
      </section>

      <NodeDivider />

      {/* ── SCREEN 4: Comparison ── */}
      <section className="py-24 px-6">
        <RevealSection>
          <div className="max-w-[1000px] mx-auto">
            <p className="text-center text-sm tracking-[0.25em] uppercase font-medium mb-4" style={{ color: "var(--primary)" }}>Сравнение</p>
            <h2 className="text-center text-3xl md:text-4xl font-bold mb-4 text-[var(--text-main)]" style={{ letterSpacing: "-0.02em" }}>Трекер калорий vs. ejeweeka</h2>
            <p className="text-center mb-16" style={{ color: "var(--text-muted)" }}>Что умеют обычные приложения — и что добавляет ejeweeka</p>

            <div className="grid md:grid-cols-2 gap-6">
              {/* Left column: Typical tracker */}
              <div className="rounded-3xl p-8" style={{ background: "rgba(0,0,0,0.02)", border: "1px solid var(--border)" }}>
                <div className="text-center mb-6">
                  <span className="text-xs tracking-[0.2em] uppercase font-semibold" style={{ color: "var(--text-muted)" }}>Трекер калорий</span>
                </div>
                <div className="space-y-4">
                  {[
                    "Подсчёт калорий вручную",
                    "Общие рекомендации",
                    "Стандартная база продуктов",
                    "Дневник питания",
                    "Графики веса",
                  ].map((item, i) => (
                    <div key={i} className="flex items-center gap-3 py-2">
                      <div className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0" style={{ border: "1.5px solid var(--border)" }}>
                        <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2.5 5L4.5 7L7.5 3" stroke="var(--text-muted)" strokeWidth="1.2" fill="none" strokeLinecap="round"/></svg>
                      </div>
                      <span className="text-sm" style={{ color: "var(--text-muted)" }}>{item}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Right column: ejeweeka */}
              <div className="rounded-3xl p-8 relative overflow-hidden" style={{ background: "linear-gradient(135deg, rgba(139,92,246,0.06), rgba(217,70,239,0.04))", border: "1px solid rgba(139,92,246,0.2)" }}>
                <div className="absolute top-0 right-0 w-32 h-32 rounded-full opacity-[0.08]" style={{ background: "radial-gradient(circle, var(--primary), transparent 70%)", transform: "translate(30%, -30%)" }} />
                <div className="text-center mb-6">
                  <span className="text-xs tracking-[0.2em] font-bold" style={{ color: "var(--primary)" }}>ejeweeka</span>
                </div>
                <div className="space-y-4 relative z-10">
                  {[
                    { text: "Всё, что умеет трекер", bold: false },
                    { text: "+ Гео-адаптация рациона", bold: true },
                    { text: "+ Учёт совместимости витаминов", bold: true },
                    { text: "+ Мгновенный пересчёт при срыве", bold: true },
                    { text: "+ AI фото-анализ тарелки", bold: true },
                    { text: "+ Пошаговые рецепты (3 варианта)", bold: true },
                    { text: "+ Адаптивные тренировки", bold: true },
                    { text: "+ Умный список покупок", bold: true },
                    { text: "+ Zero-Knowledge приватность", bold: true },
                  ].map((item, i) => (
                    <div key={i} className="flex items-center gap-3 py-2 group">
                      <div
                        className="w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 transition-transform duration-300 group-hover:scale-110"
                        style={i === 0 ? { border: "1.5px solid var(--primary)" } : { background: "var(--gradient-neon-mark)", boxShadow: "0 0 8px rgba(139,92,246,0.3)" }}
                      >
                        <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2.5 5L4.5 7L7.5 3" stroke={i === 0 ? "var(--primary)" : "#FFF"} strokeWidth="1.2" fill="none" strokeLinecap="round"/></svg>
                      </div>
                      <span className={`text-sm ${item.bold ? 'font-semibold' : ''}`} style={{ color: item.bold ? "var(--text-main)" : "var(--text-muted)" }}>{item.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </RevealSection>
      </section>

      <NodeDivider />

      {/* ── SCREEN 5: Day Timeline ── */}
      <section className="py-24 px-6">
        <RevealSection>
          <div className="max-w-[1000px] mx-auto">
            <p className="text-center text-sm tracking-[0.25em] uppercase font-medium mb-4" style={{ color: "var(--primary)" }}>Один день</p>
            <h2 className="text-center text-3xl md:text-4xl font-bold mb-16 text-[var(--text-main)]" style={{ letterSpacing: "-0.02em" }}>Как работает ejeweeka</h2>
            <div className="relative">
              {/* Vertical line */}
              <div className="absolute left-6 md:left-1/2 top-0 bottom-0 w-px" style={{ background: "var(--border)" }} />
              {[
                { time: "07:00", title: "Наглядный план", desc: "Один взгляд на экран — и ты знаешь, что на завтрак и какие витамины выпить с едой." },
                { time: "13:00", title: "Фото вместо весов", desc: "Ешь в кафе? Просто сфотографируй тарелку. Калории и макросы посчитаются сами." },
                { time: "16:00", title: "Без чувства вины", desc: "Съел десерт? Система мгновенно пересчитает ужин, чтобы ты остался в балансе." },
                { time: "20:00", title: "Адаптивная тренировка", desc: "Нагрузка, адаптированная под твой уровень энергии и цель именно сегодня." },
              ].map((t, i) => (
                <div key={i} className={`relative flex items-start gap-6 mb-12 ${i % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'}`}>
                  <div className="absolute left-6 md:left-1/2 -translate-x-1/2 w-3 h-3 rounded-full" style={{ background: "var(--primary)", boxShadow: "0 0 12px rgba(76,29,149,0.5)" }} />
                  <div className={`ml-14 md:ml-0 md:w-1/2 ${i % 2 === 0 ? 'md:pr-12' : 'md:pl-12'}`}>
                    <div className="text-sm font-bold mb-1" style={{ color: "var(--primary)" }}>{t.time}</div>
                    <h3 className="text-xl font-bold text-[var(--text-main)] mb-2">{t.title}</h3>
                    <p className="text-sm" style={{ color: "var(--text-muted)" }}>{t.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </RevealSection>
      </section>

      <NodeDivider />

      {/* ── SCREEN 6: CTA ── */}
      <section className="py-32 px-6">
        <RevealSection className="text-center">
          <div className="max-w-[600px] mx-auto relative z-10">
            <Image
              src="/brand/eje-mark-transparent.png"
              alt="ejeweeka"
              width={120}
              height={120}
              className="mx-auto mb-8"
              style={{ filter: "drop-shadow(0 0 40px rgba(139,92,246,0.4))" }}
            />
            <h2 className="text-3xl md:text-4xl font-bold mb-4 text-[var(--text-main)]" style={{ letterSpacing: "-0.02em" }}>Попробуй бесплатно</h2>
            <p className="mb-8 text-lg font-medium" style={{ color: "var(--text-muted)" }}>Все функции без ограничений на 3 дня!</p>
            <Link
              href="/subscribe"
              className="inline-block px-10 py-4 text-lg font-semibold rounded-2xl transition-all duration-300 hover:scale-[1.03]"
              style={{ background: "var(--gradient-neon-mark)", color: "#FFF" }}
            >
              Начать
            </Link>
          </div>
        </RevealSection>
      </section>

      {/* ── Footer ── */}
      <footer className="py-16 px-6" style={{ borderTop: "1px solid var(--border)" }}>
        <div className="max-w-[1000px] mx-auto flex flex-col items-center gap-6">
          <div className="flex items-center gap-4">
            <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={160} height={50} style={{ height: 'auto' }} />
          </div>
          <p className="text-xs tracking-[0.2em] uppercase" style={{ color: "var(--text-muted)" }}>be more · feel alive</p>
          <div className="flex items-center gap-6 text-sm" style={{ color: "var(--text-muted)" }}>
            <Link href="/subscribe" className="hover:text-[var(--text-main)] transition-colors">О продукте</Link>
            <Link href="/subscribe" className="hover:text-[var(--text-main)] transition-colors">Статусы</Link>
          </div>
          <div className="mt-4 max-w-[600px] text-center p-4 rounded-xl" style={{ background: "rgba(255,255,255,0.02)" }}>
            <p className="text-xs leading-relaxed" style={{ color: "var(--text-muted)" }}>
              ejeweeka — информационный wellness-сервис. Не является медицинской рекомендацией, диагностикой или лечением.
            </p>
          </div>
          <p className="text-xs" style={{ color: "var(--text-muted)" }}>© 2026 ejeweeka</p>
        </div>
      </footer>
    </div>
  );
}
