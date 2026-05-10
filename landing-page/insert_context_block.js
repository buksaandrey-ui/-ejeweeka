const fs = require('fs');
const file = '/Users/andreybuksa/Downloads/aidiet-docs/landing-page/src/components/tails/LandingTailA.tsx';
let content = fs.readFileSync(file, 'utf8');

const newSection = `
      {/* НОВЫЙ БЛОК: Контекст, который меняет план */}
      <section className="relative py-32 overflow-hidden bg-[#0A0A0A] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal text-center">
          <div className="badge-hc !bg-white/10 !border-white/20 !text-white mx-auto mb-4 w-fit">Ваш контекст</div>
          <h2 className="mb-6 text-white max-w-[800px] mx-auto">Обычный трекер видит калории.<br/>Health Code видит контекст.</h2>
          <p className="max-w-[700px] mx-auto text-gray-400 mb-16 text-lg">
            На рацион влияют не только цель и вес. Важны ограничения, аллергии, добавки, голодание, тренировки, любимые продукты и то, что вы точно не будете есть.
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
                Аллергены исключаются из блюд и покупок. План строится вокруг вашей безопасности, а не требует проверять каждую строчку рецепта.
              </p>
            </div>

            {/* Карточка 3 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] hover:bg-white/10 transition-colors">
              <h3 className="text-xl font-bold text-[#F5922B] mb-4">Витамины связаны с рационом</h3>
              <p className="text-gray-400 text-sm leading-relaxed">
                Если вы принимаете добавки, Health Code помогает встроить их в день: например, поставить витамин D рядом с приёмом пищи, где есть жиры, а железо не ставить рядом с кофе.
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
                Уберите то, что не едите, и отметьте то, что хотите видеть чаще. Health Code сохранит цель, но сделает план ближе к вашей реальной жизни.
              </p>
            </div>

            {/* Карточка 6 */}
            <div className="p-8 bg-white/5 border border-white/10 rounded-[24px] relative overflow-hidden group hover:border-[#52B044]/30 transition-colors">
              <div className="absolute top-0 right-0 p-6 opacity-10 group-hover:opacity-20 transition-opacity">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#52B044" strokeWidth="2"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>
              </div>
              <h3 className="text-xl font-bold text-[#52B044] mb-4">Важные особенности учтены</h3>
              <p className="text-gray-400 text-sm leading-relaxed relative z-10">
                Если у вас есть состояния или ограничения, влияющие на питание, Health Code учитывает их в wellness-плане. <span className="text-white font-medium">Без диагнозов, лечения и медицинских назначений.</span>
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

`;

content = content.replace(
  '      {/* Вариант C: Сравнение */}',
  newSection + '      {/* Вариант C: Сравнение */}'
);

fs.writeFileSync(file, content);
console.log("Successfully inserted the Context block");
