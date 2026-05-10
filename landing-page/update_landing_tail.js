const fs = require('fs');
const path = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/tails/LandingTailA.tsx';
let content = fs.readFileSync(path, 'utf8');

// 1. Insert Uniqueness Block after the "Система вместо трекера" summary div
const systemSummaryEnd = 'разрозненную систему из приложений, заметок, таблиц и догадок.\n            </p>\n          </div>\n        </div>\n      </section>';

const uniquenessBlock = `разрозненную систему из приложений, заметок, таблиц и догадок.
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
              <div className="text-xl font-extrabold text-white text-center leading-tight">Health<br/><span className="text-[#F5922B]">Code</span></div>
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
      </section>`;

content = content.replace(systemSummaryEnd, uniquenessBlock);

// 2. Insert Geo-adaptation Block after Context block
const contextBlockEnd = 'только потом собирает блюда, рецепты и покупки.\n            </p>\n          </div>\n        </div>\n      </section>';

const geoBlock = `только потом собирает блюда, рецепты и покупки.
            </p>
          </div>
        </div>
      </section>

      {/* НОВЫЙ БЛОК: Гео-адаптация */}
      <section className="relative py-24 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-hc mx-auto mb-4 w-fit">Локация и бюджет</div>
          <h2 className="mb-6">Рацион под ваш город, а не под абстрактную диету</h2>
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
                <p className="text-[#A1A1A6] text-sm leading-relaxed">План адаптируется под вашу локацию и привычный продуктовый контекст.</p>
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
      </section>`;

content = content.replace(contextBlockEnd, geoBlock);

// 3. Update Comparison Block
content = content.replace(
  'Считает только блюда, требует ручной ввод',
  'Считает калории, требует ручного ввода'
);
content = content.replace(
  'Не планирует готовку и покупки',
  'Почти не учитывает локацию, бюджет и цены'
);
content = content.replace(
  'Не объясняет, как скорректировать день при срыве',
  'Не предлагает выбор блюд под приём пищи'
);

content = content.replace(
  'Связывает рацион с тренировками и отдыхом',
  'Подбирает привычные продукты под бюджет'
);
content = content.replace(
  'Пошаговые рецепты и списки покупок под ритм',
  'Связывает выбор блюд, рецепты и покупки'
);


// 4. Insert Infographic Stepper after Comparison block
const comparisonBlockEnd = '<strong>HC:</strong> Мягкий пересчёт плана на лету без морализаторства.\n              </div>\n            </details>\n          </div>\n        </div>\n      </section>';

const infographicBlock = `<strong>HC:</strong> Мягкий пересчёт плана на лету без морализаторства.
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
      </section>`;

content = content.replace(comparisonBlockEnd, infographicBlock);

// 5. Insert Gold Choice Block before Statuses
const storytellingEnd = '</div>\n          </div>\n        </div>\n      </section>';
const statusesStart = '{/* Статусы */}';
const insertPointStatuses = content.indexOf(statusesStart);

const goldChoiceBlock = `
      {/* НОВЫЙ БЛОК: Выбор в Gold */}
      <section className="relative py-24 overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1000px] reveal text-center">
          <div className="badge-hc mx-auto mb-4 w-fit">Свобода выбора</div>
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
`;

content = content.substring(0, insertPointStatuses) + goldChoiceBlock + content.substring(insertPointStatuses);

// 6. Update Status Texts
content = content.replace(
  'Первый план и базовое понимание, как Health Code работает под ваш профиль.',
  'Познакомиться с базовым планом.'
);
content = content.replace(
  'Питание, рецепты, покупки, витамины, прогресс и Health Connect.',
  'План на неделю, рецепты, покупки, витамины, Health Connect, 2 варианта блюд.'
);
content = content.replace(
  'Фото-анализ, больше вариантов блюд, тренировки и глубокая коррекция плана.',
  'Максимум свободы и персонализации: до 3 вариантов блюд на каждый приём пищи, фото-анализ, тренировки и глубокая коррекция.'
);
content = content.replace(
  'Общий план, покупки и семейные сценарии для 4 человек.',
  'Общий план и покупки для семьи.'
);


fs.writeFileSync(path, content);
console.log("Successfully updated LandingTailA.tsx with all new blocks");
