"use client";

import React, { useState } from 'react';
import { LandingTemplateProps } from '../../data/landing-content';
import Image from 'next/image';

export default function LandingTailC(props: LandingTemplateProps) {
  const [activeStatus, setActiveStatus] = useState<string>('gold');
  const [isLoading, setIsLoading] = useState(false);
  const handleCheckout = () => {
    setIsLoading(true);
    setTimeout(() => {
      window.location.href = '/success';
    }, 1500);
  };

  return (
    <>
      {/* Вариант C: Сравнение */}
      <section className="relative py-32 overflow-hidden bg-[var(--bg)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje">Сравнение</div>
          <h2 className="mb-6">Почему обычного трекера уже недостаточно</h2>
          <p className="max-w-[700px] mx-auto text-[var(--text-muted)] mb-16 text-lg">
            Проблема не в том, что трекеры плохо считают калории. Проблема в том, что жизнь сложнее: тренировки, напитки, готовка, покупки, ограничения и срывы живут отдельно.
          </p>

          {/* Desktop/Tablet Comparison */}
          <div className="hidden md:grid grid-cols-2 gap-8 text-left">
            {/* Трекер */}
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-3xl opacity-60">
              <h3 className="text-xl font-bold text-[var(--text-muted)] mb-8 text-center">Обычный трекер</h3>
              <ul className="space-y-6">
                <li className="flex items-start gap-4 text-[var(--text-muted)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Считает только блюда, требует ручной ввод
                </li>
                <li className="flex items-start gap-4 text-[var(--text-muted)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Редко учитывает перекусы и напитки
                </li>
                <li className="flex items-start gap-4 text-[var(--text-muted)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Не связывает питание с тренировками
                </li>
                <li className="flex items-start gap-4 text-[var(--text-muted)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Не планирует готовку и покупки
                </li>
                <li className="flex items-start gap-4 text-[var(--text-muted)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Не объясняет, как скорректировать день при срыве
                </li>
              </ul>
            </div>

            {/* ejeweeka */}
            <div className="p-8 bg-[var(--surface)] border-2 border-[var(--primary)] rounded-3xl relative shadow-2xl">
              <div className="absolute top-0 right-0 p-6 opacity-10">
                <svg width="64" height="64" viewBox="0 0 32 32" fill="none" stroke="var(--primary)" strokeWidth="2"><circle cx="16" cy="16" r="6"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="16" y1="26" x2="16" y2="30"/><line x1="2" y1="16" x2="6" y2="16"/><line x1="26" y1="16" x2="30" y2="16"/><line x1="6.34" y1="6.34" x2="9.17" y2="9.17"/><line x1="22.83" y1="22.83" x2="25.66" y2="25.66"/><line x1="25.66" y1="6.34" x2="22.83" y2="9.17"/><line x1="9.17" y1="22.83" x2="6.34" y2="25.66"/></svg>
              </div>
              <h3 className="text-xl font-bold text-[var(--primary)] mb-8 text-center relative z-10">ejeweeka</h3>
              <ul className="space-y-6 relative z-10">
                <li className="flex items-start gap-4 text-[var(--text-main)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Распознаёт еду по фото
                </li>
                <li className="flex items-start gap-4 text-[var(--text-main)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Учитывает перекусы, напитки и алкоголь
                </li>
                <li className="flex items-start gap-4 text-[var(--text-main)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Связывает рацион с тренировками и отдыхом
                </li>
                <li className="flex items-start gap-4 text-[var(--text-main)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Пошаговые рецепты и списки покупок под ритм
                </li>
                <li className="flex items-start gap-4 text-[var(--text-main)]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Мягко корректирует план без чувства вины
                </li>
              </ul>
            </div>
          </div>

          {/* Mobile Comparison (Accordion) */}
          <div className="md:hidden space-y-4 text-left">
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">Калории <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[var(--text-muted)]">
                <strong>Обычный:</strong> Ручной ввод блюд.<br/><br/>
                <strong>HC:</strong> Распознавание по фото, учёт перекусов и алкоголя.
              </div>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">Готовка <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[var(--text-muted)]">
                <strong>Обычный:</strong> Нет планирования покупок и рецептов.<br/><br/>
                <strong>HC:</strong> Пошаговые рецепты, заготовки на 2-3 дня, общий список продуктов.
              </div>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">Тренировки <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[var(--text-muted)]">
                <strong>Обычный:</strong> Тренировки живут в другом приложении.<br/><br/>
                <strong>HC:</strong> Белок под силовые, углеводное окно, инструкции к упражнениям.
              </div>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-[var(--text-main)] list-none flex justify-between">Коррекция <span className="text-[var(--primary)] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[var(--text-muted)]">
                <strong>Обычный:</strong> Красный цвет калорий и чувство вины при срыве.<br/><br/>
                <strong>HC:</strong> Мягкий пересчёт плана на лету без морализаторства.
              </div>
            </details>
          </div>
        </div>
      </section>

      {/* Статусы Decision Helper */}
      <section className="section-padding bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal">
          <h2 className="text-center mb-8">Какой статус выбрать?</h2>
          
          <div className="flex flex-wrap justify-center gap-4 mb-12">
            <button onClick={() => setActiveStatus('white')} className={`px-6 py-3 rounded-full font-bold text-sm transition-colors ${activeStatus === 'white' ? 'bg-[#D1D5DB] text-black' : 'bg-white/5 text-[var(--text-muted)] border border-white/10 hover:bg-white/10'}`}>Хочу попробовать</button>
            <button onClick={() => setActiveStatus('black')} className={`px-6 py-3 rounded-full font-bold text-sm transition-colors ${activeStatus === 'black' ? 'bg-[#9CA3AF] text-black' : 'bg-white/5 text-[var(--text-muted)] border border-white/10 hover:bg-white/10'}`}>План на неделю</button>
            <button onClick={() => setActiveStatus('gold')} className={`px-6 py-3 rounded-full font-bold text-sm transition-colors ${activeStatus === 'gold' ? 'bg-[var(--primary)] text-black' : 'bg-white/5 text-[var(--text-muted)] border border-white/10 hover:bg-white/10'}`}>Хочу максимум</button>
            <button onClick={() => setActiveStatus('family')} className={`px-6 py-3 rounded-full font-bold text-sm transition-colors ${activeStatus === 'family' ? 'bg-[#EF4444] text-[var(--text-main)]' : 'bg-white/5 text-[var(--text-muted)] border border-white/10 hover:bg-white/10'}`}>Для семьи</button>
          </div>

          <div className="max-w-[600px] mx-auto min-h-[200px]">
            {activeStatus === 'white' && (
              <div className="p-8 bg-[var(--surface)] border border-[#374151] rounded-3xl text-center transition-all">
                <h3 className="text-[var(--text-main)] text-2xl font-bold mb-4">Статус White</h3>
                <p className="text-[#9CA3AF] mb-6">Первый план и базовое понимание, как ejeweeka работает под твой профиль.</p>
                <div className="font-bold text-[var(--text-main)] text-xl">0 ₽</div>
              </div>
            )}
            {activeStatus === 'black' && (
              <div className="p-8 bg-[var(--surface)] border border-[#4B5563] rounded-3xl text-center transition-all">
                <h3 className="text-[var(--text-main)] text-2xl font-bold mb-4">Статус Black</h3>
                <p className="text-[#D1D5DB] mb-6">Питание, рецепты, покупки, витамины, прогресс и Health Connect.</p>
                <div className="font-bold text-[var(--text-main)] text-xl">490 ₽ / мес</div>
              </div>
            )}
            {activeStatus === 'gold' && (
              <div className="p-8 bg-[var(--surface)] border-2 border-[var(--primary)] rounded-3xl text-center transition-all shadow-[0_0_40px_rgba(245,146,43,0.15)] transform scale-105">
                <h3 className="text-[var(--primary)] text-2xl font-bold mb-4">Статус Gold</h3>
                <p className="text-[#D1D5DB] mb-6">Фото-анализ, больше вариантов блюд, тренировки и глубокая коррекция плана.</p>
                <div className="font-bold text-[var(--primary)] text-xl">990 ₽ / мес</div>
              </div>
            )}
            {activeStatus === 'family' && (
              <div className="p-8 bg-[#FEF2F2]/5 border border-[#FECACA]/30 rounded-3xl text-center transition-all">
                <h3 className="text-[#EF4444] text-2xl font-bold mb-4">Статус Family Gold</h3>
                <p className="text-[#9CA3AF] mb-6">Общий план, покупки и семейные сценарии для 4 человек.</p>
                <div className="font-bold text-[#EF4444] text-xl">1680 ₽ / мес</div>
              </div>
            )}
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
