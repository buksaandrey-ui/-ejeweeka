"use client";

import React, { useState } from 'react';
import { LandingTemplateProps } from '../../data/landing-content';
import Image from 'next/image';

export default function LandingTailA(props: LandingTemplateProps) {
  const [isLoading, setIsLoading] = useState(false);
  const handleCheckout = () => {
    setIsLoading(true);
    setTimeout(() => {
      window.location.href = '/success';
    }, 1500);
  };

  return (
    <>
      {/* Вариант A: Система вместо трекера */}
      <section className="relative py-32 overflow-hidden bg-[var(--bg)]">
        <div className="bento-glow-1"></div>
        <div className="bento-glow-2"></div>
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje">Система вместо трекера</div>
          <h2 className="mb-6">Что обычные трекеры не видят</h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-16 text-lg">
            Большинство приложений считает калории. Health Code собирает питание, готовку, покупки, активность, напитки и корректировки в один персональный план.
          </p>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left mb-16">
            {/* Карточка 1 */}
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] relative overflow-hidden group hover:border-[#F5922B]/30 transition-colors">
              <div className="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
              </div>
              <h3 className="text-xl font-bold text-white mb-6">План</h3>
              <div className="flex flex-wrap gap-2">
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Блюда под цель</span>
                <span className="px-3 py-1.5 bg-[#F5922B]/10 border border-[#F5922B]/20 rounded-full text-sm text-[#F5922B]">Пошаговые рецепты</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Готовка на 2–3 дня</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Список покупок</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Меньше лишних продуктов</span>
              </div>
            </div>

            {/* Карточка 2 */}
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] relative overflow-hidden group hover:border-[#52B044]/30 transition-colors">
              <div className="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#52B044" strokeWidth="2"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
              </div>
              <h3 className="text-xl font-bold text-white mb-6">Контекст</h3>
              <div className="flex flex-wrap gap-2">
                <span className="px-3 py-1.5 bg-[#52B044]/10 border border-[#52B044]/20 rounded-full text-sm text-[#52B044]">Тренировки</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Дни нагрузки и отдыха</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Витамины</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Сон</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Ограничения</span>
              </div>
            </div>

            {/* Карточка 3 */}
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] relative overflow-hidden group hover:border-[#42A5F5]/30 transition-colors">
              <div className="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#42A5F5" strokeWidth="2"><path d="M2 12h4l2-9 5 18 2-9h5"></path></svg>
              </div>
              <h3 className="text-xl font-bold text-white mb-6">Коррекция</h3>
              <div className="flex flex-wrap gap-2">
                <span className="px-3 py-1.5 bg-[#42A5F5]/10 border border-[#42A5F5]/20 rounded-full text-sm text-[#42A5F5]">Еда по фото</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Перекусы</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Напитки и алкоголь</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Пересчёт плана</span>
                <span className="px-3 py-1.5 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB]">Мягкая компенсация</span>
              </div>
            </div>
          </div>

          <div className="p-6 bg-white/5 border border-white/10 rounded-2xl max-w-[800px] mx-auto">
            <p className="text-[#A1A1A6] font-medium m-0">
              <span className="text-white">Итог:</span> Health Code заменяет не один трекер, а разрозненную систему из приложений, заметок, таблиц и догадок.
            </p>
          </div>
        </div>
      </section>

      {/* НОВЫЙ БЛОК: Уникальность (Hub-and-Spoke) */}
      <section className="relative py-24 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <h2 className="mb-6 max-w-[800px] mx-auto">Не трекер калорий.<br/><span className="text-gradient">Система, которая видит жизнь вокруг них.</span></h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-16 text-lg">
            Health Code объединяет то, что обычно живёт отдельно: блюда, рецепты, покупки, тренировки, витамины, напитки, бюджет, локацию и ограничения.
          </p>
          
          <div className="relative flex items-center justify-center min-h-[400px] py-12">
            {/* Center Node */}
            <div className="relative z-10 w-32 h-32 rounded-full bg-[#111827] border-2 border-[#F5922B] flex items-center justify-center shadow-[0_0_60px_rgba(245,146,43,0.3)]">
              <Image src="/brand/icon-symbol-orange.png" alt="Health Code" width={86} height={86} />
            </div>
            
            {/* Connecting Lines (Simulated with SVG) */}
            <svg className="absolute inset-0 w-full h-full" style={{ zIndex: 0 }}>
              <circle cx="50%" cy="50%" r="140" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="1" strokeDasharray="4 4" />
              <circle cx="50%" cy="50%" r="220" fill="none" stroke="rgba(255,255,255,0.02)" strokeWidth="1" />
            </svg>
            
            {/* Orbiting Chips */}
            <div className="absolute top-[10%] left-[20%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Бюджет</div>
            <div className="absolute top-[5%] right-[25%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Локация</div>
            <div className="absolute top-[30%] left-[5%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Витамины</div>
            <div className="absolute top-[35%] right-[10%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Тренировки</div>
            <div className="absolute bottom-[30%] left-[10%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Ограничения</div>
            <div className="absolute bottom-[20%] right-[15%] px-4 py-2 bg-[#F5922B]/10 border border-[#F5922B]/30 rounded-full text-sm text-[#F5922B] backdrop-blur-md">Рецепты</div>
            <div className="absolute bottom-[5%] left-[30%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Покупки</div>
            <div className="absolute bottom-[10%] right-[40%] px-4 py-2 bg-white/5 border border-white/10 rounded-full text-sm text-[#D1D5DB] backdrop-blur-md">Напитки</div>
          </div>
        </div>
      </section>


      {/* НОВЫЙ БЛОК: Контекст, который меняет план */}
      <section className="relative py-32 overflow-hidden bg-[#0A0A0A] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <div className="badge-eje !bg-white/10 !border-white/20 !text-white mx-auto mb-4 w-fit">Твой контекст</div>
          <h2 className="mb-6 text-white max-w-[800px] mx-auto">Обычный трекер видит калории.<br/>Health Code видит контекст.</h2>
          <p className="max-w-[700px] mx-auto text-gray-400 mb-16 text-lg">
            На рацион влияют не только цель и вес. Важны ограничения, аллергии, добавки, голодание, тренировки, любимые продукты и то, что ты точно не будешь есть.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 text-left mb-16">
            {/* Карточка 1 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] hover:bg-white/10 transition-colors">
              <h3 className="text-xl font-bold text-white mb-4">Ограничения без ручной проверки</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Веган, рыбоед, халяль, кошерное питание, без молочки или без глютена — Health Code учитывает это до генерации блюд, рецептов и списка покупок.
              </p>
            </div>
            
            {/* Карточка 2 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] hover:bg-white/10 transition-colors">
              <h3 className="text-xl font-bold text-white mb-4">Аллергии — в приоритете</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Аллергены исключаются из блюд и покупок. План строится вокруг твоей безопасности, а не требует проверять каждую строчку рецепта.
              </p>
            </div>

            {/* Карточка 3 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] hover:bg-white/10 transition-colors">
              <h3 className="text-xl font-bold text-[#F5922B] mb-4">Витамины связаны с рационом</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Если ты принимаешь добавки, Health Code помогает встроить их в день: например, поставить витамин D рядом с приёмом пищи, где есть жиры, а железо не ставить рядом с кофе.
              </p>
            </div>

            {/* Карточка 4 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] hover:bg-white/10 transition-colors">
              <h3 className="text-xl font-bold text-white mb-4">Голодание не ломает план</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Интервальное или периодическое голодание учитывается в расписании еды, тренировок, перекусов и восстановления.
              </p>
            </div>

            {/* Карточка 5 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] hover:bg-white/10 transition-colors">
              <h3 className="text-xl font-bold text-white mb-4">Рацион без нелюбимых продуктов</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Убери то, что не ешь, и отметь то, что хочешь видеть чаще. Health Code сохранит цель, но сделает план ближе к твоей реальной жизни.
              </p>
            </div>

            {/* Карточка 6 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] relative overflow-hidden group hover:border-[#52B044]/30 transition-colors">
              <div className="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#52B044" strokeWidth="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
              </div>
              <h3 className="text-xl font-bold text-[#52B044] mb-4">Важные особенности учтены</h3>
              <p className="text-gray-400 text-sm leading-relaxed relative z-10">
                Если у тебя есть состояния или ограничения, влияющие на питание, Health Code учитывает их в wellness-плане. <span className="text-white font-medium">Без диагнозов, лечения и медицинских назначений.</span>
              </p>
            </div>
          </div>

          <div className="p-6 bg-[#111827] border border-[#374151] rounded-2xl max-w-[800px] mx-auto shadow-2xl">
            <p className="text-[#D1D5DB] font-medium m-0 flex items-center justify-center gap-3">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
              Сначала алгоритм исключает то, что нельзя. Потом подбирает то, что подходит. И только потом собирает блюда, рецепты и покупки.
            </p>
          </div>
        </div>
      </section>

      {/* НОВЫЙ БЛОК: Гео-адаптация */}
      <section className="relative py-24 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje mx-auto mb-4 w-fit">Локация и бюджет</div>
          <h2 className="mb-6">Рацион под твой город, а не под абстрактную диету</h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-16 text-lg">
            Рацион в Москве, Дубае, Алматы или Лиссабоне не должен выглядеть одинаково. Health Code учитывает страну, город, привычные продукты и бюджет. Поэтому в плане появляются блюда, которые проще купить, приготовить и вписать в реальную неделю.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-left">
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex items-start gap-4 hover:border-[#F5922B]/30 transition-colors">
              <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg>
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">Страна и город</h3>
                <p className="text-[#A1A1A6] text-sm leading-relaxed">План адаптируется под твою локацию и привычный продуктовый контекст.</p>
              </div>
            </div>

            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex items-start gap-4 hover:border-[#F5922B]/30 transition-colors">
              <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">Привычные продукты</h3>
                <p className="text-[#A1A1A6] text-sm leading-relaxed">Блюда собираются из ингредиентов, которые проще найти рядом.</p>
              </div>
            </div>

            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex items-start gap-4 hover:border-[#F5922B]/30 transition-colors">
              <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">Бюджет и цены</h3>
                <p className="text-[#A1A1A6] text-sm leading-relaxed">Health Code учитывает уровень бюджета и помогает планировать закупки без случайно дорогих корзин.</p>
              </div>
            </div>

            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex items-start gap-4 hover:border-[#F5922B]/30 transition-colors">
              <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center shrink-0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">Список покупок</h3>
                <p className="text-[#A1A1A6] text-sm leading-relaxed">Продукты группируются под план, рецепты и частоту готовки без хаоса.</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Вариант C: Сравнение */}
      <section className="relative py-32 overflow-hidden bg-[var(--bg)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje">Сравнение</div>
          <h2 className="mb-6">Почему обычного трекера уже недостаточно</h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-16 text-lg">
            Проблема не в том, что трекеры плохо считают калории. Проблема в том, что жизнь сложнее: тренировки, напитки, готовка, покупки, ограничения и срывы живут отдельно.
          </p>

          {/* Desktop/Tablet Comparison */}
          <div className="hidden md:grid grid-cols-2 gap-8 text-left">
            {/* Трекер */}
            <div className="p-8 bg-[#0A0A0A] border border-[var(--border)] rounded-3xl opacity-60">
              <h3 className="text-xl font-bold text-[#A1A1A6] mb-8 text-center">Обычный трекер</h3>
              <ul className="space-y-6">
                <li className="flex items-start gap-4 text-[#A1A1A6]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Считает калории, требует ручного ввода
                </li>
                <li className="flex items-start gap-4 text-[#A1A1A6]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Редко учитывает перекусы и напитки
                </li>
                <li className="flex items-start gap-4 text-[#A1A1A6]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Не связывает питание с тренировками
                </li>
                <li className="flex items-start gap-4 text-[#A1A1A6]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Почти не учитывает локацию, бюджет и цены
                </li>
                <li className="flex items-start gap-4 text-[#A1A1A6]">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                  Не предлагает выбор блюд под приём пищи
                </li>
              </ul>
            </div>

            {/* Health Code */}
            <div className="p-8 bg-[var(--surface)] border-2 border-[#F5922B] rounded-3xl relative shadow-2xl">
              <div className="absolute top-0 right-0 p-6 opacity-10">
                <svg width="64" height="64" viewBox="0 0 32 32" fill="none" stroke="#F5922B" strokeWidth="2"><circle cx="16" cy="16" r="6"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="16" y1="26" x2="16" y2="30"/><line x1="2" y1="16" x2="6" y2="16"/><line x1="26" y1="16" x2="30" y2="16"/><line x1="6.34" y1="6.34" x2="9.17" y2="9.17"/><line x1="22.83" y1="22.83" x2="25.66" y2="25.66"/><line x1="25.66" y1="6.34" x2="22.83" y2="9.17"/><line x1="9.17" y1="22.83" x2="6.34" y2="25.66"/></svg>
              </div>
              <h3 className="text-xl font-bold text-[#F5922B] mb-8 text-center relative z-10">Health Code</h3>
              <ul className="space-y-6 relative z-10">
                <li className="flex items-start gap-4 text-white">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Распознаёт еду по фото
                </li>
                <li className="flex items-start gap-4 text-white">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Учитывает перекусы, напитки и алкоголь
                </li>
                <li className="flex items-start gap-4 text-white">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Подбирает привычные продукты под бюджет
                </li>
                <li className="flex items-start gap-4 text-white">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Связывает выбор блюд, рецепты и покупки
                </li>
                <li className="flex items-start gap-4 text-white">
                  <svg className="shrink-0 mt-1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2"><polyline points="20 6 9 17 4 12"></polyline></svg>
                  Мягко корректирует план без чувства вины
                </li>
              </ul>
            </div>
          </div>

          {/* Mobile Comparison (Accordion) */}
          <div className="md:hidden space-y-4 text-left">
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">Калории <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[#A1A1A6]">
                <strong>Обычный:</strong> Ручной ввод блюд.<br/><br/>
                <strong>HC:</strong> Распознавание по фото, учёт перекусов и алкоголя.
              </div>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">Готовка <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[#A1A1A6]">
                <strong>Обычный:</strong> Нет планирования покупок и рецептов.<br/><br/>
                <strong>HC:</strong> Пошаговые рецепты, заготовки на 2-3 дня, общий список продуктов.
              </div>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">Тренировки <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[#A1A1A6]">
                <strong>Обычный:</strong> Тренировки живут в другом приложении.<br/><br/>
                <strong>HC:</strong> Белок под силовые, углеводное окно, инструкции к упражнениям.
              </div>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">Коррекция <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span></summary>
              <div className="mt-4 pt-4 border-t border-[var(--border)] text-[#A1A1A6]">
                <strong>Обычный:</strong> Красный цвет калорий и чувство вины при срыве.<br/><br/>
                <strong>HC:</strong> Мягкий пересчёт плана на лету без морализаторства.
              </div>
            </details>
          </div>
        </div>
      </section>

      {/* НОВЫЙ БЛОК: Инфографика (Stepper) */}
      <section className="relative py-24 bg-[#0A0A0A] border-t border-[var(--border)] overflow-hidden">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <h2 className="mb-16">От локации до готового списка покупок</h2>
          
          <div className="hidden md:flex items-start justify-between relative max-w-[1000px] mx-auto">
            {/* Connecting Line */}
            <div className="absolute top-[24px] left-[5%] right-[5%] h-[2px] bg-white/10 z-0"></div>
            
            {[
              { id: 1, title: 'Локация', desc: 'Страна и город' },
              { id: 2, title: 'Бюджет', desc: 'Комфортные траты' },
              { id: 3, title: 'Продукты', desc: 'Привычное рядом' },
              { id: 4, title: 'Рецепты', desc: 'Блюда под цель' },
              { id: 5, title: 'Покупки', desc: 'Сводный список' },
              { id: 6, title: 'Коррекция', desc: 'Пересчёт по дню' }
            ].map((step) => (
              <div key={step.id} className="relative z-10 flex flex-col items-center flex-1">
                <div className="w-12 h-12 rounded-full bg-[#111827] border-2 border-[#F5922B] flex items-center justify-center text-[#F5922B] font-bold mb-4 shadow-[0_0_20px_rgba(245,146,43,0.2)]">
                  {step.id}
                </div>
                <h4 className="text-white font-bold text-sm mb-1">{step.title}</h4>
                <p className="text-[#A1A1A6] text-xs">{step.desc}</p>
              </div>
            ))}
          </div>
          
          {/* Mobile vertical stepper */}
          <div className="md:hidden flex flex-col gap-6 text-left relative pl-6 max-w-[300px] mx-auto">
            <div className="absolute top-0 bottom-0 left-[23px] w-[2px] bg-white/10 z-0"></div>
            {[
              { id: 1, title: 'Локация', desc: 'Учёт страны и города' },
              { id: 2, title: 'Бюджет', desc: 'Сколько комфортно тратить' },
              { id: 3, title: 'Продукты', desc: 'То, что привычно купить' },
              { id: 4, title: 'Рецепты', desc: 'Под цель и ограничения' },
              { id: 5, title: 'Покупки', desc: 'Список без остатков' },
              { id: 6, title: 'Коррекция', desc: 'Пересчёт по факту' }
            ].map((step) => (
              <div key={step.id} className="relative z-10 flex items-center gap-6">
                <div className="w-10 h-10 rounded-full bg-[#111827] border-2 border-[#F5922B] flex items-center justify-center text-[#F5922B] font-bold shrink-0 shadow-[0_0_15px_rgba(245,146,43,0.2)]">
                  {step.id}
                </div>
                <div>
                  <h4 className="text-white font-bold text-sm">{step.title}</h4>
                  <p className="text-[#A1A1A6] text-xs">{step.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

{/* Вариант B: Неделя с Health Code */}
      <section className="relative py-32 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <div className="badge-eje">Storytelling</div>
          <h2 className="mb-6">Одна неделя без хаоса в питании</h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-16 text-lg">
            Health Code не просто считает калории. Он помогает прожить неделю: спланировать блюда, покупки, тренировки, напитки и корректировки.
          </p>

          {/* Горизонтальный timeline */}
          <div className="flex overflow-x-auto gap-6 pb-8 snap-x snap-mandatory scrollbar-hide text-left" style={{ scrollbarWidth: 'none' }}>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[#F5922B] font-bold text-lg mb-4">Воскресенье</div>
              <p className="text-white">Соберите план, рецепты и покупки на неделю.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[#A1A1A6] font-bold text-lg mb-4">Понедельник</div>
              <p className="text-white">Быстрые блюда и пошаговые рецепты под твоё время.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[#52B044]/30 rounded-[24px]">
              <div className="text-[#52B044] font-bold text-lg mb-4">Вторник</div>
              <p className="text-white">Силовая тренировка: рацион под белок, восстановление и нагрузку.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[#A1A1A6] font-bold text-lg mb-4">Среда</div>
              <p className="text-white">Заготовки на 2–3 дня, чтобы не стоять у плиты каждый вечер.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[#42A5F5]/30 rounded-[24px]">
              <div className="text-[#42A5F5] font-bold text-lg mb-4">Пятница</div>
              <p className="text-white">Ресторан или гости: фото блюда и пересчёт плана.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[#EF4444]/30 rounded-[24px]">
              <div className="text-[#EF4444] font-bold text-lg mb-4">Суббота</div>
              <p className="text-white">Кофе, смузи, бокал вина или коктейль тоже учитываются.</p>
            </div>
            <div className="min-w-[300px] md:min-w-[340px] snap-center p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px]">
              <div className="text-[#F5922B] font-bold text-lg mb-4">Воскресенье</div>
              <p className="text-white">Смарт-отчёт показывает, что сработало и что улучшить.</p>
            </div>
          </div>

          <div className="mt-16 text-center">
            <h3 className="text-2xl font-bold mb-8">Так Health Code заменяет 5 отдельных инструментов</h3>
            <div className="flex flex-wrap justify-center gap-4">
              <span className="px-6 py-3 bg-[#0A0A0A] border border-white/10 rounded-full text-[#A1A1A6]">Трекер калорий</span>
              <span className="px-6 py-3 bg-[#0A0A0A] border border-white/10 rounded-full text-[#A1A1A6]">Приложение рецептов</span>
              <span className="px-6 py-3 bg-[#0A0A0A] border border-white/10 rounded-full text-[#A1A1A6]">Список покупок</span>
              <span className="px-6 py-3 bg-[#0A0A0A] border border-white/10 rounded-full text-[#A1A1A6]">Дневник активности</span>
              <span className="px-6 py-3 bg-[#0A0A0A] border border-white/10 rounded-full text-[#A1A1A6]">Заметки про витамины</span>
            </div>
          </div>
        </div>
      </section>


      {/* НОВЫЙ БЛОК: Выбор в Gold */}
      <section className="relative py-24 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje mx-auto mb-4 w-fit">Свобода выбора</div>
          <h2 className="mb-6">В Gold на каждый приём пищи есть выбор</h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-16 text-lg">
            До 3 вариантов блюд помогают не срываться с плана: выберите быстрее, сытнее, бюджетнее или лучше подходящее под тренировку. Не хочется овсянку? Откройте другой вариант.
          </p>
          
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 max-w-[900px] mx-auto">
            <div className="bg-[#111827] border border-[#374151] rounded-3xl overflow-hidden shadow-xl text-left flex flex-col group hover:border-[#F5922B]/50 transition-all">
              <div className="h-32 bg-gray-800 relative">
                <div className="absolute inset-0 bg-gradient-to-t from-[#111827] to-transparent"></div>
                <div className="absolute bottom-4 left-4">
                  <span className="px-3 py-1 bg-white/10 backdrop-blur text-white text-xs rounded-full border border-white/20">Вариант 1</span>
                </div>
              </div>
              <div className="p-6 flex-1 flex flex-col">
                <h4 className="text-white font-bold mb-2">Гречка с куриным филе</h4>
                <div className="text-[#A1A1A6] text-xs flex gap-3 mb-6"><span>420 ккал</span><span>Б: 35г</span><span>15 мин</span></div>
                <button className="mt-auto w-full py-2 bg-white/5 border border-white/10 rounded-xl text-sm font-medium text-white group-hover:bg-[#F5922B] group-hover:text-black group-hover:border-[#F5922B] transition-colors">Выбрать</button>
              </div>
            </div>
            
            <div className="bg-[#111827] border-2 border-[#F5922B] rounded-3xl overflow-hidden shadow-[0_0_30px_rgba(245,146,43,0.15)] text-left flex flex-col transform sm:-translate-y-4">
              <div className="h-32 bg-gray-800 relative">
                <div className="absolute inset-0 bg-gradient-to-t from-[#111827] to-transparent"></div>
                <div className="absolute bottom-4 left-4">
                  <span className="px-3 py-1 bg-[#F5922B] text-black font-bold text-xs rounded-full">Больше белка</span>
                </div>
              </div>
              <div className="p-6 flex-1 flex flex-col">
                <h4 className="text-[#F5922B] font-bold mb-2">Омлет с лососем и шпинатом</h4>
                <div className="text-[#A1A1A6] text-xs flex gap-3 mb-6"><span>450 ккал</span><span>Б: 42г</span><span>10 мин</span></div>
                <button className="mt-auto w-full py-2 bg-[#F5922B] text-black rounded-xl text-sm font-bold">Выбрать</button>
              </div>
            </div>

            <div className="bg-[#111827] border border-[#374151] rounded-3xl overflow-hidden shadow-xl text-left flex flex-col group hover:border-[#F5922B]/50 transition-all">
              <div className="h-32 bg-gray-800 relative">
                <div className="absolute inset-0 bg-gradient-to-t from-[#111827] to-transparent"></div>
                <div className="absolute bottom-4 left-4">
                  <span className="px-3 py-1 bg-white/10 backdrop-blur text-white text-xs rounded-full border border-white/20">Бюджетно</span>
                </div>
              </div>
              <div className="p-6 flex-1 flex flex-col">
                <h4 className="text-white font-bold mb-2">Овсяноблин с сыром</h4>
                <div className="text-[#A1A1A6] text-xs flex gap-3 mb-6"><span>380 ккал</span><span>Б: 20г</span><span>5 мин</span></div>
                <button className="mt-auto w-full py-2 bg-white/5 border border-white/10 rounded-xl text-sm font-medium text-white group-hover:bg-[#F5922B] group-hover:text-black group-hover:border-[#F5922B] transition-colors">Выбрать</button>
              </div>
            </div>
          </div>
        </div>
      </section>
{/* Статусы */}
      <section className="section-padding bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal">
          <h2 className="text-center mb-4">Выберите уровень сопровождения</h2>
          <p className="text-center text-[#A1A1A6] mb-12 max-w-[600px] mx-auto">Начните с Gold-доступа на 3 дня, затем оставьте тот уровень, который подходит твоему ритму.</p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-6 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex flex-col">
              <div className="text-xs text-[#9CA3AF] uppercase tracking-wider font-bold mb-2">Познакомиться</div>
              <h3 className="text-white text-xl font-bold mb-4">White</h3>
              <p className="text-[#9CA3AF] text-sm mb-6 flex-1">Познакомиться с базовым планом.</p>
            </div>
            
            <div className="p-6 bg-[var(--surface)] border border-[var(--border)] rounded-3xl flex flex-col">
              <div className="text-xs text-[#A1A1A6] uppercase tracking-wider font-bold mb-2">Система на неделю</div>
              <h3 className="text-white text-xl font-bold mb-4">Black</h3>
              <p className="text-[#9CA3AF] text-sm mb-6 flex-1">План на неделю, рецепты, покупки, витамины, Health Connect, 2 варианта блюд.</p>
            </div>

            <div className="p-6 bg-[#111827] border-2 border-[#F5922B] rounded-3xl flex flex-col relative transform md:-translate-y-4 shadow-2xl">
              <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-[#F5922B] text-black text-[10px] font-bold uppercase tracking-wider px-3 py-1 rounded-full">Рекомендуем</div>
              <div className="text-xs text-[#F5922B] uppercase tracking-wider font-bold mb-2">Максимум</div>
              <h3 className="text-[#F5922B] text-xl font-bold mb-4">Gold</h3>
              <p className="text-[#D1D5DB] text-sm mb-6 flex-1">Максимум свободы и персонализации: до 3 вариантов блюд на каждый приём пищи, фото-анализ, тренировки и глубокая коррекция.</p>
            </div>

            <div className="p-6 bg-[var(--surface)] border border-[#FECACA]/20 rounded-3xl flex flex-col">
              <div className="text-xs text-[#EF4444] uppercase tracking-wider font-bold mb-2">Для семьи</div>
              <h3 className="text-[#EF4444] text-xl font-bold mb-4">Family</h3>
              <p className="text-[#9CA3AF] text-sm mb-6 flex-1">Общий план и покупки для семьи.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ZERO KNOWLEDGE */}
      <section className="section-padding relative overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-eje mx-auto mb-4 w-fit">Privacy First</div>
          <h2 className="mb-4">Данные профиля остаются на устройстве</h2>
          <p className="max-w-[700px] mx-auto text-[#A1A1A6] mb-12">Health Code работает по Zero-Knowledge принципу: профиль, ограничения и привычки хранятся локально, а для генерации плана используется обезличенный запрос.</p>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-white">Профиль локально</div>
            </div>
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-white">Обезличенный запрос</div>
            </div>
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-white">Wellness-only</div>
            </div>
            <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
              <div className="text-sm font-bold text-white">Без диагнозов</div>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="section-padding bg-[var(--surface)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[800px] reveal">
          <h2 className="text-center mb-12">Частые вопросы</h2>
          <div className="space-y-4">
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Health Code заменяет врача?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Нет. Это wellness-сервис для питания, сна и активности. Он не ставит диагнозы и не назначает лечение.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Что даёт Gold-доступ на 3 дня?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Можно посмотреть расширенные возможности: больше вариантов блюд, фото-анализ, коррекцию плана и продвинутые сценарии.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Можно ли учитывать напитки и алкоголь?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Да. Health Code учитывает перекусы, напитки и алкогольные калории, чтобы план отражал реальный день.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Можно готовить не каждый день?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Да. Можно собрать план под ежедневную готовку, заготовки на 2–3 дня или подготовку на неделю.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Тренировки входят в план?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Да. Health Code может учитывать активность и подбирать питание под дни нагрузки и отдыха. Для тренировок используются упражнения, инструкции и чек-листы.</p>
            </details>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section id="cta" className="section-padding bg-[var(--bg)] text-center border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[800px] reveal">
          <h2>Соберите первый план под свой ритм</h2>
          <p className="mb-12 text-[#A1A1A6]">Питание, готовка, покупки, тренировки, напитки и корректировки — в одной системе.</p>
          <div className="flex flex-col sm:flex-row justify-center gap-4">
            <button 
              onClick={handleCheckout} 
              disabled={isLoading}
              className="btn-primary-eje px-8 py-4 text-lg min-w-[240px] flex items-center justify-center disabled:opacity-70"
            >
              {isLoading ? 'Загрузка...' : 'Начать с Gold-доступа'}
            </button>
            <button className="px-8 py-4 text-lg font-medium text-white bg-white/5 border border-white/10 rounded-2xl hover:bg-white/10 transition-colors">
              Посмотреть статусы
            </button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-16 px-6 text-center text-sm text-[var(--text-muted)] border-t border-[var(--border)]">
        <div className="container mx-auto max-w-[1200px]">
          <div className="flex items-center justify-center gap-4 text-2xl font-extrabold mb-8">
            <Image src="/brand/logo-horizontal-white.png" alt="Health Code" width={240} height={54} />
          </div>
          <div className="max-w-[800px] mx-auto mb-8 p-6 bg-[#0A0A0A] rounded-2xl text-[0.85rem] leading-relaxed text-[#A1A1A6]">
            <strong>ВНИМАНИЕ: НЕ ЯВЛЯЕТСЯ МЕДИЦИНСКОЙ РЕКОМЕНДАЦИЕЙ.</strong><br/>
            Health Code — информационный wellness-сервис для питания, сна и активности. Не является медицинским изделием, медицинской услугой, телемедициной, диагностикой или лечением.
          </div>
          <p>© 2026 Health Code. Все права защищены.<br/>
          <a href="/privacy" className="text-[var(--text-main)] mt-4 inline-block">Политика конфиденциальности</a></p>
        </div>
      </footer>
    </>
  );
}
