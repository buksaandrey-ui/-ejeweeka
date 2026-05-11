"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";
import Link from "next/link";

/* ── Connected-Node SVG decorators (brand pattern) ── */
const NodeDivider = () => (
  <div className="flex items-center justify-center gap-2 py-12 opacity-[0.15]">
    <svg width="8" height="8"><circle cx="4" cy="4" r="3" fill="#9333EA"/></svg>
    <svg width="40" height="2"><line x1="0" y1="1" x2="40" y2="1" stroke="#9333EA" strokeWidth="1"/></svg>
    <svg width="12" height="12"><circle cx="6" cy="6" r="5" fill="#9333EA"/></svg>
    <svg width="40" height="2"><line x1="0" y1="1" x2="40" y2="1" stroke="#9333EA" strokeWidth="1"/></svg>
    <svg width="6" height="6"><circle cx="3" cy="3" r="2.5" fill="#9333EA"/></svg>
    <svg width="40" height="2"><line x1="0" y1="1" x2="40" y2="1" stroke="#9333EA" strokeWidth="1"/></svg>
    <svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="#9333EA"/></svg>
  </div>
);

/* ── Feature SVG illustrations (unique per feature) ── */
const featureSVGs: Record<string, React.ReactNode> = {
  params: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      {[{x:60,y:20,r:5},{x:30,y:40,r:4},{x:90,y:35,r:4},{x:20,y:70,r:3},{x:50,y:55,r:5},{x:80,y:60,r:4},{x:40,y:85,r:3},{x:70,y:80,r:4},{x:100,y:75,r:3},{x:15,y:50,r:3},{x:105,y:50,r:3},{x:60,y:100,r:4}].map((n,i) => (
        <React.Fragment key={i}>
          <circle cx={n.x} cy={n.y} r={n.r} fill="#9333EA" opacity={0.3 + Math.random()*0.7}/>
          {i > 0 && <line x1={n.x} y1={n.y} x2={[{x:60,y:20},{x:30,y:40},{x:90,y:35},{x:20,y:70},{x:50,y:55},{x:80,y:60},{x:40,y:85},{x:70,y:80},{x:100,y:75},{x:15,y:50},{x:105,y:50},{x:60,y:100}][(i-1)].x} y2={[{x:60,y:20},{x:30,y:40},{x:90,y:35},{x:20,y:70},{x:50,y:55},{x:80,y:60},{x:40,y:85},{x:70,y:80},{x:100,y:75},{x:15,y:50},{x:105,y:50},{x:60,y:100}][(i-1)].y} stroke="#9333EA" strokeWidth="0.5" opacity="0.2"/>}
        </React.Fragment>
      ))}
    </svg>
  ),
  photo: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <rect x="30" y="25" width="60" height="75" rx="8" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.6"/>
      <circle cx="60" cy="55" r="15" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="60" cy="55" r="6" fill="#9333EA" opacity="0.4"/>
      {[0,60,120,180,240,300].map((a,i) => <line key={i} x1={60+Math.cos(a*Math.PI/180)*20} y1={55+Math.sin(a*Math.PI/180)*20} x2={60+Math.cos(a*Math.PI/180)*30} y2={55+Math.sin(a*Math.PI/180)*30} stroke="#9333EA" strokeWidth="0.8" opacity="0.3"/>)}
    </svg>
  ),
  vitamins: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <circle cx="35" cy="40" r="12" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="85" cy="40" r="12" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="60" cy="85" r="12" fill="none" stroke="#52B044" strokeWidth="1.5" opacity="0.8"/>
      <line x1="47" y1="40" x2="73" y2="40" stroke="#FF4444" strokeWidth="1" opacity="0.5" strokeDasharray="4 2"/>
      <line x1="35" y1="52" x2="52" y2="77" stroke="#52B044" strokeWidth="1" opacity="0.5"/>
      <line x1="85" y1="52" x2="68" y2="77" stroke="#52B044" strokeWidth="1" opacity="0.5"/>
      <text x="35" y="44" textAnchor="middle" fill="#9333EA" fontSize="8" fontWeight="bold">Fe</text>
      <text x="85" y="44" textAnchor="middle" fill="#9333EA" fontSize="8" fontWeight="bold">Ca</text>
      <text x="60" y="89" textAnchor="middle" fill="#52B044" fontSize="8" fontWeight="bold">D3</text>
    </svg>
  ),
  geo: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      {[{x:30,y:30},{x:70,y:25},{x:100,y:45},{x:20,y:60},{x:55,y:55},{x:85,y:70},{x:35,y:90},{x:75,y:90}].map((p,i) => <circle key={i} cx={p.x} cy={p.y} r="3" fill="#9333EA" opacity="0.2"/>)}
      <circle cx="55" cy="55" r="8" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.9"/>
      <circle cx="55" cy="55" r="3" fill="#9333EA" opacity="0.8"/>
      <circle cx="55" cy="55" r="18" fill="none" stroke="#9333EA" strokeWidth="0.5" opacity="0.2"/>
      <circle cx="55" cy="55" r="30" fill="none" stroke="#9333EA" strokeWidth="0.3" opacity="0.1"/>
    </svg>
  ),
  recalc: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <polyline points="10,80 30,75 50,70 60,85 70,50 90,45 110,40" fill="none" stroke="#94A3B8" strokeWidth="1.5" strokeDasharray="3 2"/>
      <polyline points="10,80 30,75 50,70 60,55 70,50 90,45 110,40" fill="none" stroke="#9333EA" strokeWidth="1.5"/>
      <circle cx="60" cy="85" r="4" fill="#94A3B8"/>
      <circle cx="60" cy="55" r="4" fill="#9333EA"/>
      <line x1="60" y1="82" x2="60" y2="58" stroke="#9333EA" strokeWidth="0.8" opacity="0.5" strokeDasharray="2 1"/>
    </svg>
  ),
  shopping: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <circle cx="60" cy="60" r="35" fill="none" stroke="#9333EA" strokeWidth="0.5" opacity="0.2"/>
      <circle cx="45" cy="45" r="15" fill="#9333EA" opacity="0.1" stroke="#9333EA" strokeWidth="0.8"/>
      <circle cx="75" cy="50" r="12" fill="#9333EA" opacity="0.1" stroke="#9333EA" strokeWidth="0.8"/>
      <circle cx="55" cy="75" r="13" fill="#9333EA" opacity="0.1" stroke="#9333EA" strokeWidth="0.8"/>
      <circle cx="45" cy="45" r="3" fill="#9333EA" opacity="0.6"/><circle cx="75" cy="50" r="3" fill="#9333EA" opacity="0.6"/><circle cx="55" cy="75" r="3" fill="#9333EA" opacity="0.6"/>
    </svg>
  ),
  privacy: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <path d="M60 20 L95 40 L95 70 Q95 100 60 110 Q25 100 25 70 L25 40 Z" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.4"/>
      <rect x="50" y="55" width="20" height="16" rx="3" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.8"/>
      <path d="M54 55 L54 48 Q54 42 60 42 Q66 42 66 48 L66 55" fill="none" stroke="#9333EA" strokeWidth="1.5" opacity="0.8"/>
      <circle cx="60" cy="63" r="2" fill="#9333EA"/>
    </svg>
  ),
  fasting: (
    <svg viewBox="0 0 120 120" className="w-full h-full">
      <circle cx="60" cy="60" r="40" fill="none" stroke="var(--border-accent)" strokeWidth="1.5"/>
      <path d="M60 20 A40 40 0 0 1 97 73" fill="none" stroke="#9333EA" strokeWidth="4" opacity="0.8" strokeLinecap="round"/>
      <path d="M97 73 A40 40 0 0 1 23 73" fill="none" stroke="var(--border-accent)" strokeWidth="4" strokeLinecap="round"/>
      <path d="M23 73 A40 40 0 0 1 60 20" fill="none" stroke="var(--border-accent)" strokeWidth="4" strokeLinecap="round"/>
      <circle cx="60" cy="60" r="2" fill="#9333EA"/>
      <text x="60" y="56" textAnchor="middle" fill="#64748B" fontSize="7">16:8</text>
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
    <div className="min-h-screen" style={{ background: "#FAFAFA", color: "#0F172A" }}>

      {/* ── Sticky Nav (appears on scroll) ── */}
      <nav
        className="fixed top-0 left-0 right-0 z-50 transition-all duration-300"
        style={{
          transform: showNav ? "translateY(0)" : "translateY(-100%)",
          background: "rgba(255,255,255,0.92)",
          backdropFilter: "blur(24px)",
          WebkitBackdropFilter: "blur(24px)",
        }}
      >
        <div className="max-w-[1200px] mx-auto flex justify-between items-center h-16 px-6">
          <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={160} height={50} priority style={{ height: 'auto' }} />
          <div className="flex items-center gap-6">
            <a href="#features" className="text-sm hover:text-slate-900 transition-colors" style={{ color: "var(--text-muted)" }}>О продукте</a>
            <Link href="/variant-a" className="text-sm font-semibold transition-colors" style={{ color: "#9333EA" }}>Начать</Link>
          </div>
        </div>
      </nav>

      {/* ── SCREEN 1: Hero (100vh) ── */}
      <section className="min-h-screen flex flex-col items-center justify-center px-6 relative overflow-hidden" style={{ background: "var(--bg)" }}>
        {/* Subtle light spots — like a textured wall */}
        <div className="absolute top-[20%] left-[15%] w-[500px] h-[500px] rounded-full opacity-[0.06]" style={{ background: "radial-gradient(circle, #64748B, transparent 60%)" }} />
        <div className="absolute top-[60%] right-[10%] w-[400px] h-[400px] rounded-full opacity-[0.04]" style={{ background: "radial-gradient(circle, #94A3B8, transparent 60%)" }} />
        <div className="absolute top-[10%] right-[30%] w-[300px] h-[300px] rounded-full opacity-[0.03]" style={{ background: "radial-gradient(circle, rgba(147,51,234,0.3), transparent 60%)" }} />

        <div className={`relative z-10 flex flex-col items-center transition-all duration-[2s] ease-out ${heroVisible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'}`}>
          <Image
            src="/brand/ejeweeka-inline-wordmark.png"
            alt="Ежевика — be more · feel alive"
            width={853}
            height={268}
            priority
            style={{ maxWidth: "min(600px, 80vw)", height: "auto" }}
          />
          <button
            onClick={scrollToContent}
            className={`mt-12 px-12 py-4 rounded-full text-lg font-medium transition-all duration-[2s] delay-500 hover:bg-white/5 cursor-pointer ${heroVisible ? 'opacity-100' : 'opacity-0'}`}
            style={{ border: "1px solid rgba(0,0,0,0.18)", color: "#0F172A" }}
          >
            Начать
          </button>
        </div>
      </section>

      {/* ── SCREEN 2: Key Message ── */}
      <section className="py-32 md:py-40 px-6 relative overflow-hidden" style={{ background: "var(--bg)" }}>
        {/* Decorative brand symbol */}
        <div className="absolute -right-16 top-1/2 -translate-y-1/2 opacity-[0.04] pointer-events-none">
          <Image src="/brand/eje-app-icon-master.png" alt="" width={400} height={400} aria-hidden />
        </div>
        <div className="absolute -left-20 top-[30%] opacity-[0.03] pointer-events-none rotate-45">
          <Image src="/brand/eje-app-icon-master.png" alt="" width={250} height={250} aria-hidden />
        </div>
        <RevealSection>
          <div className="max-w-[900px] mx-auto text-center relative z-10">
            <h2 className="text-3xl md:text-5xl lg:text-6xl font-extrabold leading-tight mb-6" style={{ letterSpacing: "-0.02em" }}>
              Ежевика — персональный наставник
              <span className="block" style={{ color: "#9333EA" }}>по питанию, сну и активности</span>
            </h2>
            <p className="max-w-[700px] mx-auto text-base md:text-lg leading-relaxed mb-14" style={{ color: "#475569" }}>
              Учитывает цель, город, бюджет, продукты рядом, время на готовку, тренировки, ограничения, витамины и вкусы — чтобы собрать план, который реально можно соблюдать.
            </p>
            <div className="flex items-center justify-center gap-8 md:gap-12">
              {[{ num: "60+", label: "параметров" }, { num: "12", label: "недель" }, { num: "24/7", label: "адаптация" }].map((s, i) => (
                <div key={i} className="text-center">
                  <div className="text-3xl md:text-4xl font-extrabold" style={{ color: "#9333EA" }}>{s.num}</div>
                  <div className="text-xs md:text-sm mt-1" style={{ color: "#94A3B8" }}>{s.label}</div>
                </div>
              ))}
            </div>
          </div>
        </RevealSection>
      </section>

      <NodeDivider />

      {/* ── SCREEN 3: 8 Killer Features ── */}
      <section id="features" className="py-24 px-6">
        <RevealSection>
          <div className="max-w-[1200px] mx-auto">
            <p className="text-center text-sm tracking-[0.25em] uppercase font-medium mb-4" style={{ color: "#9333EA" }}>Уникальные возможности</p>
            <h2 className="text-center text-3xl md:text-4xl font-bold mb-16" style={{ letterSpacing: "-0.02em" }}>Чего нет ни у кого</h2>

            {/* Bento grid: 2 large + 6 small */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {features.map((f, i) => (
                <div
                  key={f.key}
                  className={`group rounded-2xl p-6 transition-all duration-300 hover:scale-[1.01] ${f.large ? 'lg:col-span-2 lg:row-span-2' : ''}`}
                  style={{
                    background: "rgba(255,255,255,0.02)",
                  }}
                >
                  <div className={`${f.large ? 'w-32 h-32 md:w-40 md:h-40' : 'w-16 h-16'} mx-auto mb-4 transition-transform duration-300 group-hover:scale-110`}>
                    {featureSVGs[f.key]}
                  </div>
                  <h3 className={`font-bold text-slate-900 mb-2 ${f.large ? 'text-xl' : 'text-base'}`}>{f.title}</h3>
                  <p className="text-sm leading-relaxed" style={{ color: "#64748B" }}>{f.desc}</p>
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
          <div className="max-w-[800px] mx-auto text-center">
            <p className="text-sm tracking-[0.25em] uppercase font-medium mb-4" style={{ color: "#9333EA" }}>Сравнение</p>
            <h2 className="text-3xl md:text-4xl font-bold mb-4" style={{ letterSpacing: "-0.02em" }}>Трекер калорий vs. Ежевика</h2>
            <p className="mb-12" style={{ color: "#64748B" }}>7 функций, которых нет в обычных приложениях для подсчёта калорий.</p>
            <Image src="/brand/homepage/comparison.png" alt="Ежевика vs Calorie Tracker" width={800} height={800} className="w-full" />
          </div>
        </RevealSection>
      </section>

      <NodeDivider />

      {/* ── SCREEN 5: Day Timeline ── */}
      <section className="py-24 px-6">
        <RevealSection>
          <div className="max-w-[1000px] mx-auto">
            <p className="text-center text-sm tracking-[0.25em] uppercase font-medium mb-4" style={{ color: "#9333EA" }}>Один день</p>
            <h2 className="text-center text-3xl md:text-4xl font-bold mb-16" style={{ letterSpacing: "-0.02em" }}>Как работает Ежевика</h2>
            <div className="relative">
              {/* Vertical line */}
              <div className="absolute left-6 md:left-1/2 top-0 bottom-0 w-px" style={{ background: "var(--bg)" }} />
              {[
                { time: "07:00", title: "Наглядный план", desc: "Один взгляд на экран — и ты знаешь, что на завтрак и какие витамины выпить с едой." },
                { time: "13:00", title: "Фото вместо весов", desc: "Ешь в кафе? Просто сфотографируй тарелку. Калории и макросы посчитаются сами." },
                { time: "16:00", title: "Без чувства вины", desc: "Съел десерт? Система мгновенно пересчитает ужин, чтобы ты остался в балансе." },
                { time: "20:00", title: "Адаптивная тренировка", desc: "Нагрузка, адаптированная под твой уровень энергии и цель именно сегодня." },
              ].map((t, i) => (
                <div key={i} className={`relative flex items-start gap-6 mb-12 ${i % 2 === 0 ? 'md:flex-row' : 'md:flex-row-reverse'} md:text-${i % 2 === 0 ? 'right' : 'left'}`}>
                  <div className="absolute left-6 md:left-1/2 -translate-x-1/2 w-3 h-3 rounded-full" style={{ background: "#9333EA", boxShadow: "0 0 12px rgba(147,51,234,0.5)" }} />
                  <div className={`ml-14 md:ml-0 md:w-1/2 ${i % 2 === 0 ? 'md:pr-12' : 'md:pl-12'}`}>
                    <div className="text-sm font-bold mb-1" style={{ color: "#9333EA" }}>{t.time}</div>
                    <h3 className="text-xl font-bold text-slate-900 mb-2">{t.title}</h3>
                    <p className="text-sm" style={{ color: "#64748B" }}>{t.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </RevealSection>
      </section>

      <NodeDivider />

      {/* ── SCREEN 6: CTA ── */}
      <section className="py-32 px-6 relative overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 opacity-[0.03] pointer-events-none">
          <Image src="/brand/eje-app-icon-master.png" alt="" width={500} height={500} aria-hidden />
        </div>
        <RevealSection className="text-center">
          <div className="max-w-[600px] mx-auto relative z-10">
            <Image
              src="/brand/eje-app-icon-master.png"
              alt="ejeweeka"
              width={180}
              height={180}
              className="mx-auto mb-8"
              style={{ filter: "drop-shadow(0 0 60px rgba(147,51,234,0.3))" }}
            />
            <h2 className="text-3xl md:text-4xl font-bold mb-4" style={{ letterSpacing: "-0.02em" }}>Попробуй бесплатно</h2>
            <p className="mb-8" style={{ color: "#64748B" }}>Без привязки карт. Без ограничений по времени.</p>
            <Link
              href="/variant-a"
              className="inline-block px-10 py-4 text-lg font-semibold rounded-2xl transition-all duration-300 hover:scale-[1.03]"
              style={{ background: "var(--gradient-neon-mark)", color: "#FFF" }}
            >
              Начать
            </Link>
          </div>
        </RevealSection>
      </section>

      {/* ── Footer ── */}
      <footer className="py-16 px-6" style={{ borderTop: "1px solid rgba(0,0,0,0.06)" }}>
        <div className="max-w-[1000px] mx-auto flex flex-col items-center gap-6">
          <div className="flex items-center gap-4">
            <Image src="/brand/eje-app-icon-master.png" alt="" width={32} height={32} className="opacity-40" />
            <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={160} height={50} style={{ height: 'auto' }} />
          </div>
          <p className="text-xs tracking-[0.2em] uppercase" style={{ color: "var(--text-muted)" }}>be more · feel alive</p>
          <div className="flex items-center gap-6 text-sm" style={{ color: "#94A3B8" }}>
            <Link href="/variant-a" className="hover:text-slate-900 transition-colors">О продукте</Link>
            <Link href="/subscribe" className="hover:text-slate-900 transition-colors">Статусы</Link>
          </div>
          <div className="mt-4 max-w-[600px] text-center p-4 rounded-xl" style={{ background: "rgba(255,255,255,0.02)" }}>
            <p className="text-xs leading-relaxed" style={{ color: "var(--text-muted)" }}>
              Ежевика — информационный wellness-сервис. Не является медицинской рекомендацией, диагностикой или лечением.
            </p>
          </div>
          <p className="text-xs" style={{ color: "var(--text-muted)" }}>© 2026 Ежевика</p>
        </div>
      </footer>
    </div>
  );
}
