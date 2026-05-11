"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { LandingTemplateProps } from "../data/landing-content";

import LandingTailA from './tails/LandingTailA';
import LandingTailB from './tails/LandingTailB';
import LandingTailC from './tails/LandingTailC';

export default function LandingTemplate(props: LandingTemplateProps & { audienceId?: string }) {
  const [isLoading, setIsLoading] = useState(false);
  const [activeStatus, setActiveStatus] = useState("gold");

  const handleCheckout = async (e: React.MouseEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          audienceId: props.audienceId || 'default',
          tier: 'gold' 
        })
      });
      
      if (!res.ok) throw new Error('Checkout failed');
      
      const data = await res.json();
      
      // If mock environment, backend returns yookassa URL, but we can simulate redirect locally
      if (data.url.includes('yookassa.ru/checkout') && process.env.NODE_ENV === 'development') {
         window.location.href = `/success?payment_id=${data.paymentId}`;
      } else {
         window.location.href = data.url;
      }
      
    } catch (error) {
      console.error(error);
      alert('Ошибка при создании платежа. Попробуй позже.');
      setIsLoading(false);
    }
  };

  useEffect(() => {
    // Intersection Observer for scroll animations
    const observerOptions = { root: null, rootMargin: '0px', threshold: 0.1 };
    const observer = new IntersectionObserver((entries, obs) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('active');
          obs.unobserve(entry.target);
        }
      });
    }, observerOptions);
    
    document.querySelectorAll('.reveal').forEach(el => observer.observe(el));

    // Parallax Effect for Mockups
    const handleScroll = () => {
      requestAnimationFrame(() => {
        document.querySelectorAll<HTMLElement>('.iphone-frame').forEach(el => {
          const speed = 0.08;
          const rect = el.parentElement?.getBoundingClientRect();
          if (rect) {
            const yPos = (window.innerHeight / 2 - rect.top) * speed;
            el.style.setProperty('--parallax-y', `${yPos}px`);
          }
        });
      });
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <>
      <nav className="nav-eje">
        <div className="container nav-content flex justify-between items-center h-[100px] px-6 mx-auto max-w-[1200px]">
          <div className="logo flex items-center gap-4">
            <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={240} height={54} priority />
          </div>
          <a href="/subscribe" className="btn-primary-eje py-2 px-6">Сравнить статусы</a>
        </div>
      </nav>

      {/* БЛОК 1: Hero */}
      <section className="hero section-padding relative pt-48 text-center overflow-hidden">
        <div className="hero-glow"></div>
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <h1>ejeweeka — персональный наставник <br/><span className="text-gradient">по питанию, сну и активности</span></h1>
          <p className="text-center max-w-[800px] mx-auto mb-10 text-xl text-[var(--text-muted)]">
            Учитывает цель, город, бюджет, продукты рядом, время на готовку, тренировки, ограничения, витамины и вкусы — чтобы собрать план, который реально можно соблюдать.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-4">
            <a href="/subscribe" className="btn-primary-eje text-lg px-8 py-4">Собрать свой план</a>
            <a href="#features" className="px-8 py-4 text-[var(--text-main)] hover:text-[var(--primary)] transition-colors border border-white/20 rounded-[20px] font-bold">Посмотреть, как работает</a>
          </div>
          <p className="text-sm text-[var(--text-muted)] mb-16">Wellness-рекомендации. Не диагностика и не лечение.</p>
          
          <div className="flex justify-center reveal perspective-[1400px] mt-8">
            <div className="iphone-glow"></div>
            <div className="iphone-frame hero-iphone-frame relative overflow-hidden bg-[var(--surface)]">
              <iframe
                src="https://main-screens.vercel.app/h1-dashboard.html"
                className="w-full h-full border-0 pointer-events-none"
                style={{ transform: 'scale(0.75)', transformOrigin: 'top left', width: '133%', height: '133%' }}
                title="ejeweeka Dashboard"
                loading="lazy"
              />
            </div>
          </div>
        </div>
      </section>

      {/* БЛОК 2: Проблема */}
      <section className="section-padding bg-[var(--surface)] overflow-hidden">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="flex flex-col md:flex-row items-center gap-16 max-w-[1200px] mx-auto">
            <div className="flex-1">
              <div className="badge-eje mb-4">Больше, чем калории</div>
              <h2 className="mb-6">Обычный трекер видит калории. ejeweeka видит жизнь вокруг них.</h2>
              <p className="text-left mb-6 text-[var(--text-muted)]">Город, бюджет, продукты рядом, тренировки, витамины, напитки, ограничения, микробиом, голодание и вкусы — всё это влияет на план. ejeweeka собирает эти данные в одну систему.</p>
              <p className="text-left font-semibold text-[var(--primary)]">Редкий случай, когда всё это собрано в одной системе.</p>
            </div>
            <div className="flex-1 flex flex-wrap gap-3 justify-center md:justify-start">
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">📍 Локация</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">💰 Бюджет</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🛒 Продукты рядом</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🍱 3 варианта блюд</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🏃‍♂️ Тренировки</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">💊 Витамины</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">☕ Напитки</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🍷 Алкоголь</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">⏱ Голодание</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🚫 Ограничения</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🤧 Аллергии</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">🦠 Кишечник</div>
              <div className="px-5 py-2 bg-[var(--bg)] border border-[var(--border)] rounded-full text-sm font-medium">❤️ Вкусы</div>
            </div>
          </div>
        </div>
      </section>

      {/* БЛОК 3: Смарт-ядро */}
      <section className="section-padding">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <div className="badge-eje">Технология</div>
          <h2>Конец эпохи мифов. <br/>Только чистые данные.</h2>
          <p className="max-w-[800px] mx-auto mb-12">
            Обычные поисковики выдают усредненные советы. Фитнес-блогеры раздают рекомендации, которые работают только для них. Мы пошли другим путем. ejeweeka работает на базе алгоритмической базы, построенной на научных исследованиях.
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
            <div className="stat-card">
              <div className="stat-number">16k+</div>
              <div className="text-[var(--text-muted)]">Научных материалов и экспертных протоколов в базе знаний.</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">30+</div>
              <div className="text-[var(--text-muted)]">Практикующих специалистов, кандидатов и докторов наук в экспертной базе.</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">60+</div>
              <div className="text-[var(--text-muted)]">Персональных параметров учитывается алгоритмом при составлении плана.</div>
            </div>
          </div>
        </div>
      </section>

      {/* СЦЕНАРИИ */}
      <section className="section-padding bg-[var(--surface)] overflow-hidden">
        <div className="container mx-auto px-6 max-w-[1200px]">
          {props.scenarios && props.scenarios.map((scenario, idx) => (
            <div key={idx} className={`scenario-row reveal flex flex-col md:flex-row items-center gap-16 mb-40 md:py-12 ${idx % 2 !== 0 ? 'md:flex-row-reverse' : ''}`}>
              <div className="scenario-content flex-1">
                <div className="badge-eje">{scenario.badge}</div>
                <h2>{scenario.title}</h2>
                <p className="italic mb-4 text-[var(--text-muted)]">{scenario.problem}</p>
                <p><strong>Как это работает:</strong> {scenario.solution}</p>
              </div>
              <div className="scenario-visual flex-1 flex items-center justify-center relative perspective-[1400px]">
                <div className="iphone-glow"></div>
                <div className="iphone-frame relative overflow-hidden bg-[var(--surface)]">
                  <iframe
                    src={idx === 0 ? 'https://main-screens.vercel.app/p1-weekly-plan.html' : idx === 1 ? 'https://main-screens.vercel.app/ph1-photo-analysis.html' : 'https://main-screens.vercel.app/pr1-progress.html'}
                    className="w-full h-full border-0 pointer-events-none"
                    style={{ transform: 'scale(0.75)', transformOrigin: 'top left', width: '133%', height: '133%' }}
                    title={`Screen ${idx + 1}`}
                    loading="lazy"
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* БЛОК 7: Микро-менеджмент (Dark Section) */}
      <section className="section-padding bg-[var(--surface)] text-[var(--text-main)]">
        <div className="container mx-auto px-6 max-w-[800px] text-center reveal">
          <div className="badge-eje !bg-white/10 !border-white/20 !text-[var(--text-main)]">Киллер-фича</div>
          <h2 className="text-[var(--text-main)]">Забота на микроуровне.</h2>
          <p className="text-[var(--text-muted)]">Пьешь железо с утренним кофе? Скорее всего, оно просто не усваивается. Принимаешь витамин D₃ без правильных жиров? Деньги на ветер.</p>
          <p className="text-[var(--text-muted)]">ejeweeka берет на себя заботу о твоих витаминах. Мы напомним, что с чем пить, чтобы получить 100% пользы, и разведем конфликтующие элементы по времени.</p>
          
          <div className="flex flex-wrap justify-center gap-3 mt-8">
            <div className="px-6 py-3 bg-white/5 border border-white/10 rounded-full font-medium">Железо ≠ Кофе</div>
            <div className="px-6 py-3 bg-white/5 border border-white/10 rounded-full font-medium">D₃ + Жиры</div>
            <div className="px-6 py-3 bg-white/5 border border-white/10 rounded-full font-medium">Магний на ночь</div>
            <div className="px-6 py-3 bg-white/5 border border-white/10 rounded-full font-medium">Циркадные ритмы</div>
          </div>
        </div>
      </section>

      {/* БЛОК 8: Один день (Timeline) */}
      <section className="section-padding bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <h2 className="text-center mb-12">Вся рутина — на автопилоте.</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <span className="font-extrabold text-[var(--primary)] mb-3 block">07:00 | Утро</span>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Наглядный план</h3>
              <p className="text-[var(--text-muted)]">Один взгляд на экран — и ты знаешь, что на завтрак, а какие витамины выпить с едой.</p>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <span className="font-extrabold text-[var(--primary)] mb-3 block">13:00 | Обед</span>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Фото вместо весов</h3>
              <p className="text-[var(--text-muted)]">Ешь в кафе с коллегами? Просто сфотографируй тарелку. Калории посчитаются сами.</p>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <span className="font-extrabold text-[var(--primary)] mb-3 block">16:00 | Перекус</span>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Без чувства вины</h3>
              <p className="text-[var(--text-muted)]">Съел десерт? Система мгновенно пересчитает ужин, чтобы ты остался в балансе.</p>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <span className="font-extrabold text-[var(--primary)] mb-3 block">20:00 | Вечер</span>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Нагрузки</h3>
              <p className="text-[var(--text-muted)]">Тренировка, адаптированная под твой уровень энергии и цель именно сегодня.</p>
            </div>
          </div>
        </div>
      </section>

      
      {/* NEW BLOCKS START */}

      {/* Гео-адаптация */}
      <section className="section-padding bg-[var(--surface)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="text-center mb-16">
            <div className="badge-eje mx-auto mb-4 w-fit">Локализация</div>
            <h2>Рацион под твой город, а не под абстрактную диету</h2>
            <p className="max-w-[700px] mx-auto text-[var(--text-muted)]">ejeweeka учитывает страну, город, привычные продукты и доступность ингредиентов, чтобы блюда было реально купить и приготовить.</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-[1000px] mx-auto">
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Страна и город</h3>
              <p className="text-[var(--text-muted)]">План адаптируется под твою локацию и привычный продуктовый контекст.</p>
            </div>
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Привычные продукты</h3>
              <p className="text-[var(--text-muted)]">Блюда собираются из ингредиентов, которые проще найти рядом.</p>
            </div>
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Бюджет и цены</h3>
              <p className="text-[var(--text-muted)]">ejeweeka учитывает бюджет и помогает не собирать рацион из случайно дорогих продуктов.</p>
            </div>
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Список покупок</h3>
              <p className="text-[var(--text-muted)]">Продукты группируются под план, рецепты и частоту готовки.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Инфографика */}
      <section className="section-padding bg-[var(--surface)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <h2 className="text-[var(--text-main)] mb-4">От города до списка покупок</h2>
          <p className="max-w-[700px] mx-auto text-[var(--text-muted)] mb-12">Сначала ejeweeka понимает твою локацию и бюджет. Затем подбирает продукты, собирает блюда, рецепты и покупки. После — корректирует план по фактическому дню.</p>
          
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">📍</div>
              <div className="font-bold text-[var(--text-main)] mb-1">Локация</div>
              <div className="text-sm text-[var(--text-muted)]">Страна и город</div>
            </div>
            <div className="hidden md:block text-[var(--primary)]">→</div>
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">💰</div>
              <div className="font-bold text-[var(--text-main)] mb-1">Бюджет</div>
              <div className="text-sm text-[var(--text-muted)]">Лимит затрат</div>
            </div>
            <div className="hidden md:block text-[var(--primary)]">→</div>
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">🛒</div>
              <div className="font-bold text-[var(--text-main)] mb-1">Продукты</div>
              <div className="text-sm text-[var(--text-muted)]">Доступные рядом</div>
            </div>
            <div className="hidden md:block text-[var(--primary)]">→</div>
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">🍱</div>
              <div className="font-bold text-[var(--text-main)] mb-1">Рецепты</div>
              <div className="text-sm text-[var(--text-muted)]">Под цель</div>
            </div>
          </div>
        </div>
      </section>

      {/* 3 Варианта в Gold */}
      <section className="section-padding bg-[var(--surface)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="text-center mb-12">
            <div className="badge-eje mx-auto mb-4 w-fit">Свобода выбора</div>
            <h2>В Gold ты выбираешь, что есть</h2>
            <p className="max-w-[700px] mx-auto text-[var(--text-muted)]">На каждый приём пищи ejeweeka предлагает до 3 вариантов блюд — чтобы план не ощущался как жёсткая диета. Gold даёт больше свободы: фото-анализ и глубокую коррекцию плана.</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-[1000px] mx-auto">
            <div className="p-6 bg-[var(--bg)] border border-[var(--border)] rounded-[24px] flex flex-col h-full relative overflow-hidden">
              <div className="absolute top-0 right-0 bg-green-500/20 text-green-400 text-xs px-3 py-1 rounded-bl-xl font-bold">Быстро</div>
              <h3 className="text-[var(--text-main)] text-lg font-bold mb-1 mt-4">Завтрак 1</h3>
              <p className="text-[var(--text-muted)] text-sm mb-4">15 минут • 450 ккал</p>
              <div className="flex gap-2 text-xs text-[var(--text-muted)] mb-6"><span>Б: 20</span><span>Ж: 15</span><span>У: 45</span></div>
              <button className="mt-auto py-2 w-full border border-[var(--border)] rounded-xl hover:bg-white/5 transition-colors text-[var(--text-main)] text-sm">Выбрать</button>
            </div>
            <div className="p-6 bg-[var(--bg)] border border-[var(--primary)]/50 rounded-[24px] flex flex-col h-full relative overflow-hidden shadow-[0_0_30px_rgba(245,146,43,0.1)]">
              <div className="absolute top-0 right-0 bg-[var(--primary)]/20 text-[var(--primary)] text-xs px-3 py-1 rounded-bl-xl font-bold">Сытно</div>
              <h3 className="text-[var(--text-main)] text-lg font-bold mb-1 mt-4">Завтрак 2</h3>
              <p className="text-[var(--text-muted)] text-sm mb-4">25 минут • 520 ккал</p>
              <div className="flex gap-2 text-xs text-[var(--text-muted)] mb-6"><span>Б: 35</span><span>Ж: 20</span><span>У: 30</span></div>
              <button className="mt-auto py-2 w-full bg-[var(--primary)] text-black font-bold rounded-xl hover:bg-[#E08527] transition-colors text-sm">Выбрать</button>
            </div>
            <div className="p-6 bg-[var(--bg)] border border-[var(--border)] rounded-[24px] flex flex-col h-full relative overflow-hidden">
              <div className="absolute top-0 right-0 bg-blue-500/20 text-blue-400 text-xs px-3 py-1 rounded-bl-xl font-bold">После тренировки</div>
              <h3 className="text-[var(--text-main)] text-lg font-bold mb-1 mt-4">Завтрак 3</h3>
              <p className="text-[var(--text-muted)] text-sm mb-4">20 минут • 480 ккал</p>
              <div className="flex gap-2 text-xs text-[var(--text-muted)] mb-6"><span>Б: 40</span><span>Ж: 10</span><span>У: 40</span></div>
              <button className="mt-auto py-2 w-full border border-[var(--border)] rounded-xl hover:bg-white/5 transition-colors text-[var(--text-main)] text-sm">Выбрать</button>
            </div>
          </div>
        </div>
      </section>

      {/* Ограничения */}
      <section className="section-padding bg-[var(--surface)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="flex flex-col md:flex-row gap-16 items-center">
            <div className="flex-1">
              <h2 className="text-[var(--text-main)] mb-4">План без продуктов, которые тебе нельзя или не подходят</h2>
              <p className="text-[var(--text-muted)] mb-8">ejeweeka учитывает пищевые ограничения, аллергии и нелюбимые продукты ещё до генерации блюд. Тебе не нужно вручную проверять каждое блюдо.</p>
              <ul className="space-y-4 text-[var(--text-muted)]">
                <li className="flex items-center gap-3"><span className="text-[var(--primary)]">✓</span> исключает неподходящие продукты</li>
                <li className="flex items-center gap-3"><span className="text-[var(--primary)]">✓</span> не кладёт их в список покупок</li>
                <li className="flex items-center gap-3"><span className="text-[var(--primary)]">✓</span> подбирает альтернативы</li>
                <li className="flex items-center gap-3"><span className="text-[var(--primary)]">✓</span> сохраняет разнообразие блюд</li>
              </ul>
            </div>
            <div className="flex-1">
              <div className="p-8 bg-white/5 border border-white/10 rounded-[32px]">
                <div className="text-sm text-[var(--text-muted)] mb-4">Ты указываешь:</div>
                <div className="flex flex-wrap gap-2 mb-8">
                  <span className="px-4 py-2 bg-red-500/10 text-red-400 border border-red-500/20 rounded-full text-sm">Аллергия на орехи</span>
                  <span className="px-4 py-2 bg-white/10 text-[var(--text-main)] border border-white/20 rounded-full text-sm">Без молочки</span>
                  <span className="px-4 py-2 bg-white/10 text-[var(--text-main)] border border-white/20 rounded-full text-sm">Без глютена</span>
                  <span className="px-4 py-2 bg-white/10 text-[var(--text-main)] border border-white/20 rounded-full text-sm">Веган</span>
                </div>
                <div className="text-sm text-[var(--text-muted)] mb-4">Мы балансируем:</div>
                <p className="text-[var(--text-main)]">Сохраняем цель, бюджет и разнообразие, делая план ближе к реальной жизни.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Особенности организма, Голодание, Кишечник */}
      <section className="section-padding bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <h2 className="text-center mb-16">Учитываем нюансы</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[32px]">
              <div className="text-4xl mb-4">🩺</div>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-4">Важные особенности не теряются</h3>
              <p className="text-[var(--text-muted)] mb-4">Диабет, подагра, особенности ЖКТ или женское здоровье влияют на рацион. ejeweeka учитывает их в wellness-плане.</p>
              <p className="text-xs text-[var(--text-muted)] mt-auto">Не ставит диагнозы. При заболеваниях консультируйся с врачом.</p>
            </div>
            
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[32px]">
              <div className="text-4xl mb-4">⏱</div>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-4">Голодание тоже часть плана</h3>
              <p className="text-[var(--text-muted)]">Если ты используешь интервальное голодание, ejeweeka подстраивает приёмы пищи, калорийность и тренировки под выбранное окно.</p>
            </div>
            
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[32px]">
              <div className="text-4xl mb-4">🦠</div>
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-4">Еда, после которой животу легче</h3>
              <p className="text-[var(--text-muted)] mb-4">Больше клетчатки и продуктов для микрофлоры. Не просто меньше калорий, а еда, от которой телу легче.</p>
              <p className="text-xs text-[var(--text-muted)] mt-auto">Если есть выраженные симптомы, нужна консультация специалиста.</p>
            </div>
          </div>
        </div>
      </section>

      {/* NEW BLOCKS END */}

      {props.tailVariant === 'A' && <LandingTailA {...props} />}
      {props.tailVariant === 'B' && <LandingTailB {...props} />}
      {props.tailVariant === 'C' && <LandingTailC {...props} />}
      {(!props.tailVariant || props.tailVariant === 'default') && (
        <>
          {/* БЛОК 8.5: Premium Bento Grid */}
      <section className="relative py-32 overflow-hidden bg-[var(--bg)]">
        <div className="bento-glow-1"></div>
        <div className="bento-glow-2"></div>
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <div className="badge-eje">Всё в одном приложении</div>
          <h2>6 причин навсегда удалить другие трекеры.</h2>
          
          <div className="bento-grid">
            {/* Card 1: Span 2 */}
            <div className="bento-card span-2">
              <div className="bento-bg-gradient"></div>
              <div className="bento-bg-text">HC</div>
              <div className="bento-icon"><svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round"><circle cx="16" cy="16" r="6"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="16" y1="26" x2="16" y2="30"/><line x1="2" y1="16" x2="6" y2="16"/><line x1="26" y1="16" x2="30" y2="16"/><line x1="6.34" y1="6.34" x2="9.17" y2="9.17"/><line x1="22.83" y1="22.83" x2="25.66" y2="25.66"/><line x1="25.66" y1="6.34" x2="22.83" y2="9.17"/><line x1="9.17" y1="22.83" x2="6.34" y2="25.66"/></svg></div>
              <h3>{props.bentoFeatures[0]?.title}</h3>
              <p>{props.bentoFeatures[0]?.description}</p>
            </div>

            {/* Card 2 */}
            <div className="bento-card">
              <div className="bento-bg-gradient"></div>
              <div className="bento-icon"><svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 3L6 18h10l-2 11 14-15H18z"/></svg></div>
              <h3>{props.bentoFeatures[1]?.title}</h3>
              <p>{props.bentoFeatures[1]?.description}</p>
            </div>

            {/* Card 3 */}
            <div className="bento-card">
              <div className="bento-bg-gradient"></div>
              <div className="bento-icon"><svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="6" y="14" width="20" height="16" rx="3"/><path d="M10 14v-4a6 6 0 0112 0v4"/><circle cx="16" cy="22" r="2" fill="var(--primary)"/></svg></div>
              <h3>{props.bentoFeatures[2]?.title}</h3>
              <p>{props.bentoFeatures[2]?.description}</p>
            </div>

            {/* Card 4 */}
            <div className="bento-card">
              <div className="bento-bg-gradient"></div>
              <div className="bento-icon"><svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="4" width="24" height="24" rx="4"/><circle cx="16" cy="16" r="5"/><circle cx="16" cy="16" r="1.5" fill="var(--primary)"/></svg></div>
              <h3>{props.bentoFeatures[3]?.title}</h3>
              <p>{props.bentoFeatures[3]?.description}</p>
            </div>

            {/* Card 5: Span 2 */}
            <div className="bento-card span-2">
              <div className="bento-bg-gradient"></div>
              <div className="bento-bg-text" style={{fontSize: "180px"}}>16k+</div>
              <div className="bento-icon"><svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round"><path d="M10 4c0 8 12 8 12 16s-12 8-12 8"/><path d="M22 4c0 8-12 8-12 16s12 8 12 8"/><line x1="10" y1="10" x2="22" y2="10"/><line x1="8" y1="16" x2="24" y2="16"/><line x1="10" y1="22" x2="22" y2="22"/></svg></div>
              <h3>{props.bentoFeatures[4]?.title}</h3>
              <p>{props.bentoFeatures[4]?.description}</p>
            </div>

            {/* Card 6 */}
            <div className="bento-card">
              <div className="bento-bg-gradient"></div>
              <div className="bento-icon"><svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="10" height="10" rx="2"/><rect x="19" y="3" width="10" height="10" rx="2"/><rect x="3" y="19" width="10" height="10" rx="2"/><rect x="19" y="19" width="10" height="10" rx="2"/></svg></div>
              <h3>{props.bentoFeatures[5]?.title}</h3>
              <p>{props.bentoFeatures[5]?.description}</p>
            </div>
          </div>
        </div>
      </section>

      {/* БЛОК 9: Статусы — StatusWall */}
      <section className="section-padding bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[800px] reveal">
          <div className="badge-eje text-center mx-auto w-fit mb-4">Клубная система</div>
          <h2 className="text-center mb-4">Выбери свой статус.</h2>
          <p className="text-center text-[var(--text-muted)] mb-12">Первые 3 дня — полный доступ к Gold-возможностям.</p>

          <div className="space-y-3">

            {/* Black */}
            <details 
              className="group rounded-2xl border border-[#1F2937] bg-[var(--surface)] overflow-hidden"
              open={activeStatus === "black"}
            >
              <summary 
                className="flex justify-between items-center px-6 py-5 cursor-pointer list-none"
                onClick={(e) => { e.preventDefault(); setActiveStatus("black"); }}
              >
                <span className="text-[var(--text-main)] font-bold text-lg">Статус Black</span>
                <span className="text-[#9CA3AF] text-sm">490 ₽/мес</span>
              </summary>
              <div className="px-6 pb-6 space-y-3 text-[#D1D5DB] text-sm">
                <div className="text-xs text-[var(--primary)] font-bold uppercase tracking-wider mb-4">Для тех, кто хочет полноценную систему на неделю: питание, рецепты, покупки, витамины и прогресс.</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round"><rect x="2" y="2" width="12" height="12" rx="2"/><line x1="5" y1="5" x2="11" y2="5"/><line x1="5" y1="8" x2="11" y2="8"/><line x1="5" y1="11" x2="8" y2="11"/></svg>План на неделю: питание, сон, витамины, тренировки</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 8h10M3 5h6M3 11h4"/></svg>Учет напитков и ручная коррекция плана</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round"><circle cx="8" cy="6" r="3"/><path d="M2 14c0-3.3 2.7-6 6-6s6 2.7 6 6"/></svg>2 варианта блюд с пошаговыми инструкциями</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round"><polyline points="2 10 6 6 10 9 14 4"/><rect x="2" y="12" width="12" height="2" rx="1"/></svg>Смарт-отчёты и Health Connect</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="white" strokeWidth="1.5" strokeLinecap="round"><circle cx="8" cy="8" r="6"/><path d="M8 4v4l3 3"/></svg>Совместимость лекарств и БАД</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="white" strokeWidth="1.5"><circle cx="8" cy="8" r="5" fill="none"/><path d="M5 8h6M8 5v6"/></svg>4 темы оформления</div>
              </div>
            </details>

            {/* Gold — open by default */}
            <details 
              className="group rounded-2xl border-2 border-[var(--primary)] bg-[#FFFBEB] overflow-hidden" 
              open={activeStatus === "gold"}
            >
              <summary 
                className="flex justify-between items-center px-6 py-5 cursor-pointer list-none"
                onClick={(e) => { e.preventDefault(); setActiveStatus("gold"); }}
              >
                <span className="text-[#B45309] font-bold text-lg">✦ Статус Gold</span>
                <span className="text-[#B45309] text-sm font-semibold">990 ₽/мес · 9 990 ₽/год</span>
              </summary>
              <div className="px-6 pb-6 space-y-3 text-[#92400E] text-sm">
                <div className="text-xs text-[var(--primary)] font-bold uppercase tracking-wider mb-4">Для тех, кто хочет максимум персонализации: фото-анализ, больше вариантов блюд, тренировки и глубокая коррекция плана.</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="var(--primary)" strokeWidth="1.5" strokeLinecap="round"><circle cx="8" cy="8" r="6"/><path d="M8 4v4l3 3"/></svg>3 варианта блюд с пошаговыми инструкциями</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="var(--primary)" strokeWidth="1.5" strokeLinecap="round"><rect x="2" y="3" width="12" height="10" rx="2"/><circle cx="8" cy="8" r="2"/></svg>Фото-анализ блюд (5 раз в день) с коррекцией плана</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="var(--primary)" strokeWidth="1.5" strokeLinecap="round"><path d="M4 12V7a4 4 0 018 0v5M2 12h12"/></svg>Персональные тренировки с видео</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="var(--primary)" strokeWidth="1.5"><path d="M8 2l1.5 4.5H14l-3.8 2.7 1.4 4.3L8 11l-3.6 2.5 1.4-4.3L2 6.5h4.5z"/></svg>6 тем оформления (Gold + 4 Сезона)</div>
              </div>
            </details>

            {/* Gold Family */}
            <details 
              className="group rounded-2xl border border-[#FECACA] bg-[#FEF2F2] overflow-hidden"
              open={activeStatus === "family"}
            >
              <summary 
                className="flex justify-between items-center px-6 py-5 cursor-pointer list-none"
                onClick={(e) => { e.preventDefault(); setActiveStatus("family"); }}
              >
                <span className="text-[#991B1B] font-bold text-lg">Статус Gold Family</span>
                <span className="text-[#991B1B] text-sm">990 + 690 ₽/чел · до 4 человек</span>
              </summary>
              <div className="px-6 pb-6 space-y-3 text-[#7F1D1D] text-sm">
                <div className="text-xs text-red-500 font-bold uppercase tracking-wider mb-4">Для семьи: общий план, покупки и синхронизация сценариев.</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="#EF4444" strokeWidth="1.5" strokeLinecap="round"><circle cx="5" cy="5" r="2"/><circle cx="11" cy="5" r="2"/><path d="M1 14c0-2.2 1.8-4 4-4s4 1.8 4 4"/><path d="M9 11c.6-.7 1.5-1 2-1 2.2 0 4 1.8 4 4"/></svg>Объединённый план питания для всей семьи</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="#EF4444" strokeWidth="1.5" strokeLinecap="round"><path d="M3 2h10l1 4H2L3 2z"/><path d="M2 6l1 8h10l1-8"/><path d="M6 10h4"/></svg>Общий список покупок и бюджет</div>
                <div className="flex items-center gap-3"><svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="#EF4444" strokeWidth="1.5" strokeLinecap="round"><rect x="2" y="2" width="12" height="12" rx="3"/><path d="M6 8l2 2 4-4"/></svg>E2EE синхронизация между участниками</div>
              </div>
            </details>
          </div>
        </div>
      </section>

      
      {/* ZERO KNOWLEDGE */}
      <section className="section-padding relative overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="text-center mb-16">
            <div className="badge-eje mx-auto mb-4 w-fit">Privacy First</div>
            <h2>Твой профиль остаётся на устройстве</h2>
            <p className="max-w-[700px] mx-auto text-[var(--text-muted)]">ejeweeka работает по принципу Zero-Knowledge: чувствительные данные хранятся локально, а для генерации плана используется обезличенный запрос.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[var(--primary)]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[var(--primary)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              <h3 className="text-[var(--text-main)] text-lg font-bold">Без лишнего сбора данных</h3>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[var(--primary)]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[var(--primary)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
              <h3 className="text-[var(--text-main)] text-lg font-bold">Профиль хранится локально</h3>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[var(--primary)]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[var(--primary)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
              <h3 className="text-[var(--text-main)] text-lg font-bold">Обезличенная генерация</h3>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[var(--primary)]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[var(--primary)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
              <h3 className="text-[var(--text-main)] text-lg font-bold">Wellness-only подход</h3>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="section-padding bg-[var(--surface)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[800px] reveal">
          <h2 className="text-center mb-12">Частые вопросы</h2>
          <div className="space-y-4">
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                ejeweeka заменяет врача?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Нет. ejeweeka — это информационный wellness-сервис для поддержания здорового образа жизни. Он не ставит диагнозы, не назначает лечение и не заменяет медицинскую консультацию. Все рекомендации носят исключительно нутрициологический характер.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Можно ли пользоваться бесплатно?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Да, при регистрации ты получаешь полноценный план на 3 дня — без привязки карт и без ограничений по времени.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Что даёт Gold на 3 дня?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Ты получаешь 3 дня полного доступа ко всем функциям статуса Gold, чтобы протестировать фото-анализ блюд, персональные тренировки с видео, смарт-отчёты и 3 варианта блюд. Никаких привязок карт для триала не требуется.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Как работает фото-анализ?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">На статусе Gold ты можешь сфотографировать блюдо. Нейро-модуль распознает состав, подсчитает калории и макронутриенты, а затем автоматически скорректирует твой план питания на день.</p>
            </details>
          </div>
        </div>
      </section>

      {/* БЛОК 10: CTA */}

      <section id="cta" className="section-padding bg-[var(--surface)] text-center">
        <div className="container mx-auto px-6 max-w-[800px] reveal">
          <h2>Начни с Gold. Бесплатно.</h2>
          <p className="mb-12">Первые 3 дня — полный доступ ко всем функциям Статуса Gold: фото-анализ, персональные тренировки, 3 варианта блюд и глубокая коррекция плана.</p>
          <button 
            onClick={handleCheckout} 
            disabled={isLoading}
            className="btn-primary-eje px-12 py-5 text-lg w-full max-w-sm mx-auto flex items-center justify-center disabled:opacity-70"
          >
            {isLoading ? (
              <span className="flex items-center gap-3">
                <div className="w-5 h-5 border-2 border-black border-t-transparent rounded-full animate-spin"></div>
                Загрузка...
              </span>
            ) : (
              "Активировать Status Gold"
            )}
          </button>
        </div>
      </section>

      {/* Footer с дисклеймером */}
      <footer className="py-16 px-6 text-center text-sm text-[var(--text-muted)] border-t border-[var(--border)]">
        <div className="container mx-auto max-w-[1200px]">
          <div className="flex items-center justify-center gap-4 mb-8">
            <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={240} height={54} />
          </div>
          <div className="max-w-[800px] mx-auto mb-8 p-6 bg-[var(--surface)] rounded-2xl text-[0.85rem] leading-relaxed text-[var(--text-muted)]">
            <strong>ВНИМАНИЕ: НЕ ЯВЛЯЕТСЯ МЕДИЦИНСКОЙ РЕКОМЕНДАЦИЕЙ.</strong><br/>
            Приложение ejeweeka, его алгоритмы, база знаний и любые предоставляемые советы носят исключительно информационный и рекомендательный характер. Сервис не предназначен для диагностики, лечения, облегчения симптомов или профилактики каких-либо заболеваний.
          </div>
          <p>© 2026 ejeweeka. Все права защищены.<br/>
          <a href="/privacy" className="text-[var(--text-main)] mt-4 inline-block">Политика конфиденциальности</a></p>
        </div>
      </footer>
    
        </>
      )}
    </>
  );
}
