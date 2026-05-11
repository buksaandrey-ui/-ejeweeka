"use client";

import React, { useState } from 'react';
import { LandingTemplateProps } from '../../data/landing-content';
import Image from 'next/image';

export default function LandingTailB(props: LandingTemplateProps) {
  const [isLoading, setIsLoading] = useState(false);
  const handleCheckout = () => {
    setIsLoading(true);
    setTimeout(() => {
      window.location.href = '/success';
    }, 1500);
  };

  return (
    <>
      {/* Вариант B: Неделя с ejeweeka */}
      <section className="relative py-32 overflow-hidden bg-[var(--bg)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <div className="badge-eje">Storytelling</div>
          <h2 className="mb-6">Одна неделя без хаоса в питании</h2>
          <p className="max-w-[700px] mx-auto text-[var(--text-muted)] mb-16 text-lg">
            ejeweeka не просто считает калории. Он помогает прожить неделю: спланировать блюда, покупки, тренировки, напитки и корректировки.
          </p>

          {/* Горизонтальный timeline */}
          <div className="flex overflow-x-auto gap-6 pb-8 snap-x snap-mandatory scrollbar-hide text-left" style={{ scrollbarWidth: 'none' }}>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[var(--primary)] font-bold text-lg mb-4">Воскресенье</div>
              <p className="text-[var(--text-main)]">Соберите план, рецепты и покупки на неделю.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[var(--text-muted)] font-bold text-lg mb-4">Понедельник</div>
              <p className="text-[var(--text-main)]">Быстрые блюда и пошаговые рецепты под твоё время.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[#52B044]/30 rounded-[24px]">
              <div className="text-[#52B044] font-bold text-lg mb-4">Вторник</div>
              <p className="text-[var(--text-main)]">Силовая тренировка: рацион под белок, восстановление и нагрузку.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[var(--text-muted)] font-bold text-lg mb-4">Среда</div>
              <p className="text-[var(--text-main)]">Заготовки на 2–3 дня, чтобы не стоять у плиты каждый вечер.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[#42A5F5]/30 rounded-[24px]">
              <div className="text-[#42A5F5] font-bold text-lg mb-4">Пятница</div>
              <p className="text-[var(--text-main)]">Ресторан или гости: фото блюда и пересчёт плана.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[#EF4444]/30 rounded-[24px]">
              <div className="text-[#EF4444] font-bold text-lg mb-4">Суббота</div>
              <p className="text-[var(--text-main)]">Кофе, смузи, бокал вина или коктейль тоже учитываются.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[var(--primary)] font-bold text-lg mb-4">Воскресенье</div>
              <p className="text-[var(--text-main)]">Смарт-отчёт показывает, что сработало и что улучшить.</p>
            </div>
          </div>

          <div className="mt-16 text-center">
            <h3 className="text-2xl font-bold mb-8">Так ejeweeka заменяет 5 отдельных инструментов</h3>
            <div className="flex flex-wrap justify-center gap-4">
              <span className="px-6 py-3 bg-[var(--surface)] border border-white/10 rounded-full text-[var(--text-muted)]">Трекер калорий</span>
              <span className="px-6 py-3 bg-[var(--surface)] border border-white/10 rounded-full text-[var(--text-muted)]">Приложение рецептов</span>
              <span className="px-6 py-3 bg-[var(--surface)] border border-white/10 rounded-full text-[var(--text-muted)]">Список покупок</span>
              <span className="px-6 py-3 bg-[var(--surface)] border border-white/10 rounded-full text-[var(--text-muted)]">Дневник активности</span>
              <span className="px-6 py-3 bg-[var(--surface)] border border-white/10 rounded-full text-[var(--text-muted)]">Заметки про витамины</span>
            </div>
          </div>
        </div>
      </section>

      {/* Статусы */}
      <section className="section-padding bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal">
          <h2 className="text-center mb-12">Какой статус подходит твоей неделе?</h2>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <div className="p-6 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex flex-col text-center">
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">White</h3>
              <p className="text-[var(--primary)] text-sm mb-4 font-bold">Понять базовый план</p>
            </div>
            <div className="p-6 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex flex-col text-center">
              <h3 className="text-[var(--text-main)] text-xl font-bold mb-2">Black</h3>
              <p className="text-[var(--primary)] text-sm mb-4 font-bold">Вести неделю</p>
            </div>
            <div className="p-6 bg-[var(--surface)] border-2 border-[var(--primary)] rounded-3xl flex flex-col text-center relative shadow-2xl transform md:-translate-y-2">
              <h3 className="text-[var(--primary)] text-xl font-bold mb-2">Gold</h3>
              <p className="text-[var(--primary)] text-sm mb-4 font-bold">Фото-анализ и тренировки</p>
            </div>
            <div className="p-6 bg-[var(--surface)] border border-[#FECACA]/20 rounded-3xl flex flex-col text-center">
              <h3 className="text-[#EF4444] text-xl font-bold mb-2">Family</h3>
              <p className="text-[#EF4444] text-sm mb-4 font-bold">Собрать семью</p>
            </div>
          </div>
        </div>
      </section>

      {/* ZERO KNOWLEDGE */}
      <section className="section-padding relative overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje mx-auto mb-4 w-fit">Privacy First</div>
          <h2 className="mb-4">Данные профиля остаются на устройстве</h2>
          <p className="max-w-[700px] mx-auto text-[var(--text-muted)] mb-12">ejeweeka работает по Zero-Knowledge принципу: профиль, ограничения и привычки хранятся локально, а для генерации плана используется обезличенный запрос.</p>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-[var(--text-main)]">Профиль локально</div>
            </div>
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-[var(--text-main)]">Обезличенный запрос</div>
            </div>
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-[var(--text-main)]">Wellness-only</div>
            </div>
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-[var(--text-main)]">Без диагнозов</div>
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
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Нет. Это wellness-сервис для питания, сна и активности. Он не ставит диагнозы и не назначает лечение.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Что даёт Gold-доступ на 3 дня?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Можно посмотреть расширенные возможности: больше вариантов блюд, фото-анализ, коррекцию плана и продвинутые сценарии.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Можно ли учитывать напитки и алкоголь?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Да. ejeweeka учитывает перекусы, напитки и алкогольные калории, чтобы план отражал реальный день.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Можно готовить не каждый день?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Да. Можно собрать план под ежедневную готовку, заготовки на 2–3 дня или подготовку на неделю.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">
                Тренировки входят в план?
                <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[var(--text-muted)] leading-relaxed">Да. ejeweeka может учитывать активность и подбирать питание под дни нагрузки и отдыха. Для тренировок используются упражнения, инструкции и чек-листы.</p>
            </details>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section id="cta" className="section-padding bg-[var(--bg)] text-center border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[800px] reveal">
          <h2>Соберите первый план под свой ритм</h2>
          <p className="mb-12 text-[var(--text-muted)]">Питание, готовка, покупки, тренировки, напитки и корректировки — в одной системе.</p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <button 
              onClick={handleCheckout} 
              disabled={isLoading}
              className="btn-primary-eje px-8 py-4 text-lg min-w-[240px] flex items-center justify-center disabled:opacity-70"
            >
              {isLoading ? 'Загрузка...' : 'Начать с Gold-доступа'}
            </button>
            <button className="px-8 py-4 text-lg font-medium text-[var(--text-main)] bg-white/5 border border-white/10 rounded-2xl hover:bg-white/10 transition-colors">
              Посмотреть статусы
            </button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-16 px-6 text-center text-sm text-[var(--text-muted)] border-t border-[var(--border)]">
        <div className="container mx-auto max-w-[1200px]">
          <div className="flex items-center justify-center gap-4 text-2xl font-extrabold mb-8">
            <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={240} height={54} />
          </div>
          <div className="max-w-[800px] mx-auto mb-8 p-6 bg-[var(--surface)] rounded-2xl text-[0.85rem] leading-relaxed text-[var(--text-muted)]">
            <strong>ВНИМАНИЕ: НЕ ЯВЛЯЕТСЯ МЕДИЦИНСКОЙ РЕКОМЕНДАЦИЕЙ.</strong><br/>
            ejeweeka — информационный wellness-сервис для питания, сна и активности. Не является медицинским изделием, медицинской услугой, телемедициной, диагностикой или лечением.
          </div>
          <p>© 2026 ejeweeka. Все права защищены.<br/>
          <a href="/privacy" className="text-[var(--text-main)] mt-4 inline-block">Политика конфиденциальности</a></p>
        </div>
      </footer>
    </>
  );
}
