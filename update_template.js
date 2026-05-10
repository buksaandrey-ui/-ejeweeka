import fs from 'fs';

const templateFile = 'landing-page/src/components/LandingTemplate.tsx';
let code = fs.readFileSync(templateFile, 'utf8');

// Add Trust Row to Hero
const heroStr = `<p className="text-sm text-gray-500 mb-16">Управление доступом через приватного Telegram-консьержа</p>`;
const trustRowStr = `<p className="text-sm text-gray-500 mb-8">Управление доступом через приватного Telegram-консьержа</p>
          
          <div className="flex flex-wrap justify-center gap-6 mb-16 text-sm font-medium text-[#A1A1A6] reveal perspective-[1400px]">
            <div className="flex items-center gap-2"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2.5"><path d="M20 6L9 17l-5-5"></path></svg>3 дня Gold-доступа</div>
            <div className="flex items-center gap-2"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2.5"><path d="M20 6L9 17l-5-5"></path></svg>Фото-анализ еды</div>
            <div className="flex items-center gap-2"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#F5922B" strokeWidth="2.5"><path d="M20 6L9 17l-5-5"></path></svg>Данные на устройстве</div>
          </div>`;

if (!code.includes('3 дня Gold-доступа')) {
    code = code.replace(heroStr, trustRowStr);
}

// Add FAQ and Privacy sections before CTA
const privacyAndFaq = `
      {/* ZERO KNOWLEDGE */}
      <section className="section-padding relative overflow-hidden bg-[var(--bg)] border-t border-[var(--border)]">
        <div className="container mx-auto px-6 max-w-[1200px] reveal">
          <div className="text-center mb-16">
            <div className="badge-hc mx-auto mb-4 w-fit">Privacy First</div>
            <h2>Личные данные остаются у вас</h2>
            <p className="max-w-[700px] mx-auto text-[#A1A1A6]">Health Code работает по Zero-Knowledge принципу: профиль, ограничения и привычки хранятся на устройстве. На сервер передаётся только обезличенный запрос для генерации плана.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[#F5922B]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[#F5922B]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              <h3 className="text-white text-lg font-bold">Без email и паролей</h3>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[#F5922B]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[#F5922B]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
              <h3 className="text-white text-lg font-bold">Профиль на устройстве</h3>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[#F5922B]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[#F5922B]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
              <h3 className="text-white text-lg font-bold">Обезличенная генерация</h3>
            </div>
            <div className="p-8 bg-[var(--surface)] border border-[var(--border)] rounded-[24px] text-center hover:border-[#F5922B]/30 transition-colors">
              <svg className="w-12 h-12 mx-auto mb-4 text-[#F5922B]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>
              <h3 className="text-white text-lg font-bold">Wellness-only подход</h3>
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
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Нет. Health Code — это информационный wellness-сервис для поддержания здорового образа жизни. Он не ставит диагнозы, не назначает лечение и не заменяет медицинскую консультацию. Все рекомендации носят исключительно нутрициологический характер.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Можно ли пользоваться бесплатно?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Да. Статус Free доступен всегда без ограничений по времени. Он включает персонализированный план питания на 3 дня и учет всех ваших ограничений.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Что даёт Gold на 3 дня?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">Вы получаете 3 дня полного доступа ко всем функциям статуса Gold, чтобы протестировать фото-анализ блюд, персональные тренировки с видео, смарт-отчеты и 3 варианта блюд. Никаких привязок карт для триала не требуется.</p>
            </details>
            <details className="group rounded-2xl border border-[var(--border)] bg-[#0A0A0A] overflow-hidden p-6 cursor-pointer">
              <summary className="font-bold text-lg text-white list-none flex justify-between">
                Как работает фото-анализ?
                <span className="text-[#F5922B] group-open:rotate-45 transition-transform">+</span>
              </summary>
              <p className="mt-4 text-[#A1A1A6] leading-relaxed">На статусе Gold вы можете сфотографировать блюдо. Нейро-модуль распознает состав, подсчитает калории и макронутриенты, а затем автоматически скорректирует ваш план питания на день.</p>
            </details>
          </div>
        </div>
      </section>

      {/* БЛОК 10: CTA */}
`;

if (!code.includes('Личные данные остаются у вас')) {
    code = code.replace('{/* БЛОК 10: CTA */}', privacyAndFaq);
}

fs.writeFileSync(templateFile, code);
console.log("Updated LandingTemplate.tsx with Privacy and FAQ sections.");
