const fs = require('fs');

const path = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/LandingTemplate.tsx';
let content = fs.readFileSync(path, 'utf8');

const insertionPoint = "{props.tailVariant === 'A' && <LandingTailA {...props} />}";

const newBlocks = `
      {/* NEW BLOCKS START */}

      {/* Гео-адаптация */}
      <section className="section-padding bg-[var(--surface)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="text-center mb-16">
            <div className="badge-hc mx-auto mb-4 w-fit">Локализация</div>
            <h2>Рацион под ваш город, а не под абстрактную диету</h2>
            <p className="max-w-[700px] mx-auto text-[#A1A1A6]">Health Code учитывает страну, город, привычные продукты и доступность ингредиентов, чтобы блюда было реально купить и приготовить.</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-[1000px] mx-auto">
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-white text-xl font-bold mb-2">Страна и город</h3>
              <p className="text-[#A1A1A6]">План адаптируется под вашу локацию и привычный продуктовый контекст.</p>
            </div>
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-white text-xl font-bold mb-2">Привычные продукты</h3>
              <p className="text-[#A1A1A6]">Блюда собираются из ингредиентов, которые проще найти рядом.</p>
            </div>
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-white text-xl font-bold mb-2">Бюджет и цены</h3>
              <p className="text-[#A1A1A6]">Health Code учитывает бюджет и помогает не собирать рацион из случайно дорогих продуктов.</p>
            </div>
            <div className="p-8 bg-[var(--bg)] border border-[var(--border)] rounded-[24px]">
              <h3 className="text-white text-xl font-bold mb-2">Список покупок</h3>
              <p className="text-[#A1A1A6]">Продукты группируются под план, рецепты и частоту готовки.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Инфографика */}
      <section className="section-padding bg-[#0A0A0A]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <h2 className="text-white mb-4">От города до списка покупок</h2>
          <p className="max-w-[700px] mx-auto text-gray-400 mb-12">Сначала Health Code понимает вашу локацию и бюджет. Затем подбирает продукты, собирает блюда, рецепты и покупки. После — корректирует план по фактическому дню.</p>
          
          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">📍</div>
              <div className="font-bold text-white mb-1">Локация</div>
              <div className="text-sm text-gray-400">Страна и город</div>
            </div>
            <div className="hidden md:block text-[#F5922B]">→</div>
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">💰</div>
              <div className="font-bold text-white mb-1">Бюджет</div>
              <div className="text-sm text-gray-400">Лимит затрат</div>
            </div>
            <div className="hidden md:block text-[#F5922B]">→</div>
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">🛒</div>
              <div className="font-bold text-white mb-1">Продукты</div>
              <div className="text-sm text-gray-400">Доступные рядом</div>
            </div>
            <div className="hidden md:block text-[#F5922B]">→</div>
            <div className="flex-1 p-6 bg-white/5 border border-white/10 rounded-[20px]">
              <div className="text-2xl mb-2">🍱</div>
              <div className="font-bold text-white mb-1">Рецепты</div>
              <div className="text-sm text-gray-400">Под цель</div>
            </div>
          </div>
        </div>
      </section>

      {/* 3 Варианта в Gold */}
      <section className="section-padding bg-[var(--surface)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="text-center mb-12">
            <div className="badge-hc mx-auto mb-4 w-fit">Свобода выбора</div>
            <h2>В Gold вы выбираете, что есть</h2>
            <p className="max-w-[700px] mx-auto text-[#A1A1A6]">На каждый приём пищи Health Code предлагает до 3 вариантов блюд — чтобы план не ощущался как жёсткая диета. Gold даёт больше свободы: фото-анализ и глубокую коррекцию плана.</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-[1000px] mx-auto">
            <div className="p-6 bg-[var(--bg)] border border-[var(--border)] rounded-[24px] flex flex-col h-full relative overflow-hidden">
              <div className="absolute top-0 right-0 bg-green-500/20 text-green-400 text-xs px-3 py-1 rounded-bl-xl font-bold">Быстро</div>
              <h3 className="text-white text-lg font-bold mb-1 mt-4">Завтрак 1</h3>
              <p className="text-[#A1A1A6] text-sm mb-4">15 минут • 450 ккал</p>
              <div className="flex gap-2 text-xs text-gray-500 mb-6"><span>Б: 20</span><span>Ж: 15</span><span>У: 45</span></div>
              <button className="mt-auto py-2 w-full border border-[var(--border)] rounded-xl hover:bg-white/5 transition-colors text-white text-sm">Выбрать</button>
            </div>
            <div className="p-6 bg-[var(--bg)] border border-[#F5922B]/50 rounded-[24px] flex flex-col h-full relative overflow-hidden shadow-[0_0_30px_rgba(245,146,43,0.1)]">
              <div className="absolute top-0 right-0 bg-[#F5922B]/20 text-[#F5922B] text-xs px-3 py-1 rounded-bl-xl font-bold">Сытно</div>
              <h3 className="text-white text-lg font-bold mb-1 mt-4">Завтрак 2</h3>
              <p className="text-[#A1A1A6] text-sm mb-4">25 минут • 520 ккал</p>
              <div className="flex gap-2 text-xs text-gray-500 mb-6"><span>Б: 35</span><span>Ж: 20</span><span>У: 30</span></div>
              <button className="mt-auto py-2 w-full bg-[#F5922B] text-black font-bold rounded-xl hover:bg-[#E08527] transition-colors text-sm">Выбрать</button>
            </div>
            <div className="p-6 bg-[var(--bg)] border border-[var(--border)] rounded-[24px] flex flex-col h-full relative overflow-hidden">
              <div className="absolute top-0 right-0 bg-blue-500/20 text-blue-400 text-xs px-3 py-1 rounded-bl-xl font-bold">После тренировки</div>
              <h3 className="text-white text-lg font-bold mb-1 mt-4">Завтрак 3</h3>
              <p className="text-[#A1A1A6] text-sm mb-4">20 минут • 480 ккал</p>
              <div className="flex gap-2 text-xs text-gray-500 mb-6"><span>Б: 40</span><span>Ж: 10</span><span>У: 40</span></div>
              <button className="mt-auto py-2 w-full border border-[var(--border)] rounded-xl hover:bg-white/5 transition-colors text-white text-sm">Выбрать</button>
            </div>
          </div>
        </div>
      </section>

      {/* Ограничения */}
      <section className="section-padding bg-[#0A0A0A]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="flex flex-col md:flex-row gap-16 items-center">
            <div className="flex-1">
              <h2 className="text-white mb-4">План без продуктов, которые вам нельзя или не подходят</h2>
              <p className="text-gray-400 mb-8">Health Code учитывает пищевые ограничения, аллергии и нелюбимые продукты ещё до генерации блюд. Вам не нужно вручную проверять каждое блюдо.</p>
              <ul className="space-y-4 text-gray-300">
                <li className="flex items-center gap-3"><span className="text-[#F5922B]">✓</span> исключает неподходящие продукты</li>
                <li className="flex items-center gap-3"><span className="text-[#F5922B]">✓</span> не кладёт их в список покупок</li>
                <li className="flex items-center gap-3"><span className="text-[#F5922B]">✓</span> подбирает альтернативы</li>
                <li className="flex items-center gap-3"><span className="text-[#F5922B]">✓</span> сохраняет разнообразие блюд</li>
              </ul>
            </div>
            <div className="flex-1">
              <div className="p-8 bg-white/5 border border-white/10 rounded-[32px]">
                <div className="text-sm text-gray-500 mb-4">Вы указываете:</div>
                <div className="flex flex-wrap gap-2 mb-8">
                  <span className="px-4 py-2 bg-red-500/10 text-red-400 border border-red-500/20 rounded-full text-sm">Аллергия на орехи</span>
                  <span className="px-4 py-2 bg-white/10 text-white border border-white/20 rounded-full text-sm">Без молочки</span>
                  <span className="px-4 py-2 bg-white/10 text-white border border-white/20 rounded-full text-sm">Без глютена</span>
                  <span className="px-4 py-2 bg-white/10 text-white border border-white/20 rounded-full text-sm">Веган</span>
                </div>
                <div className="text-sm text-gray-500 mb-4">Мы балансируем:</div>
                <p className="text-white">Сохраняем цель, бюджет и разнообразие, делая план ближе к реальной жизни.</p>
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
              <h3 className="text-white text-xl font-bold mb-4">Важные особенности не теряются</h3>
              <p className="text-[#A1A1A6] mb-4">Диабет, подагра, особенности ЖКТ или женское здоровье влияют на рацион. Health Code учитывает их в wellness-плане.</p>
              <p className="text-xs text-gray-600 mt-auto">Не ставит диагнозы. При заболеваниях консультируйтесь с врачом.</p>
            </div>
            
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[32px]">
              <div className="text-4xl mb-4">⏱</div>
              <h3 className="text-white text-xl font-bold mb-4">Голодание тоже часть плана</h3>
              <p className="text-[#A1A1A6]">Если вы используете интервальное голодание, Health Code подстраивает приёмы пищи, калорийность и тренировки под выбранное окно.</p>
            </div>
            
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[32px]">
              <div className="text-4xl mb-4">🦠</div>
              <h3 className="text-white text-xl font-bold mb-4">Еда, после которой животу легче</h3>
              <p className="text-[#A1A1A6] mb-4">Больше клетчатки и продуктов для микрофлоры. Не просто меньше калорий, а еда, от которой телу легче.</p>
              <p className="text-xs text-gray-600 mt-auto">Если есть выраженные симптомы, нужна консультация специалиста.</p>
            </div>
          </div>
        </div>
      </section>

      {/* NEW BLOCKS END */}
`;

content = content.replace(insertionPoint, newBlocks + '\n      ' + insertionPoint);
fs.writeFileSync(path, content);
