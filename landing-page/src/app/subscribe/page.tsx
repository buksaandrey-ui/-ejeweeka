"use client";

import React, { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";

export default function SubscribePage() {
  const router = useRouter();
  const [activeStatus, setActiveStatus] = useState("gold");
  const [uuid, setUuid] = useState("");
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [familyCount, setFamilyCount] = useState(2);

  const handleCheckout = async (e: React.MouseEvent) => {
    e.preventDefault();
    if (!agreeTerms) {
      alert("Пожалуйста, прими условия оферты и политики конфиденциальности.");
      return;
    }
    
    setIsLoading(true);
    
    try {
      const res = await fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          audienceId: 'default',
          tier: activeStatus,
          anonymous_uuid: uuid || 'anonymous'
        })
      });
      
      if (!res.ok) throw new Error('Checkout failed');
      
      const data = await res.json();
      
      // In development/mock scenario, bypass actual YooKassa URL to mock success flow
      if (data.url && data.url.includes('yookassa.ru/checkout') && process.env.NODE_ENV === 'development') {
         router.push(`/payment/success?payment_id=${data.paymentId}`);
      } else {
         window.location.href = data.url;
      }
    } catch (error) {
      console.error(error);
      alert('Ошибка при создании платежа. Попробуй позже.');
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--text-main)] font-sans antialiased pb-20">
      <nav className="nav-eje border-b border-[var(--border)]">
        <div className="container flex justify-between items-center h-[80px] px-6 mx-auto max-w-[1200px]">
          <Link href="/" className="logo flex items-center gap-4">
            <Image src="/brand/ejeweeka-inline-wordmark.png" alt="ejeweeka" width={220} height={50} priority />
          </Link>
          <Link href="/" className="text-[var(--text-muted)] hover:text-[var(--text-main)] transition-colors">Вернуться</Link>
        </div>
      </nav>

      <section className="section-padding pt-16 text-center">
        <div className="container mx-auto px-6 max-w-[800px]">
          <h1 className="mb-4 text-4xl font-extrabold">Выбери статус ejeweeka</h1>
          <p className="text-[var(--text-muted)] mb-2 text-lg">Начни с Gold-доступа и открой расширенные возможности: больше вариантов блюд, фото-анализ, тренировки и персональный план.</p>
          <p className="text-sm text-[var(--text-muted)] mb-12">Wellness-сервис. Не диагностика и не лечение.</p>

          <div className="space-y-4 text-left">
            {/* White */}
            <div 
              className={`p-6 rounded-2xl border cursor-pointer transition-all ${activeStatus === 'white' ? 'border-white bg-[var(--surface)]' : 'border-[var(--border)] bg-[var(--surface)] hover:border-white/50'}`}
              onClick={() => setActiveStatus('white')}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="text-xl font-bold text-[var(--text-main)] mb-1">Статус White</h3>
                  <div className="text-sm text-[var(--text-muted)]">Для знакомства. Базовый план и первый опыт ejeweeka.</div>
                </div>
                <div className="text-right">
                  <div className="font-bold text-lg">0 ₽</div>
                </div>
              </div>
              <ul className="text-sm text-[var(--text-muted)] mt-4 space-y-2">
                <li>• План на 3 дня</li>
                <li>• 1 вариант блюда</li>
                <li>• Базовый прогресс</li>
                <li>• Ограничения и аллергии учитываются всегда</li>
              </ul>
            </div>

            {/* Black */}
            <div 
              className={`p-6 rounded-2xl border cursor-pointer transition-all ${activeStatus === 'black' ? 'border-white bg-[var(--surface)]' : 'border-[var(--border)] bg-[var(--surface)] hover:border-white/50'}`}
              onClick={() => setActiveStatus('black')}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="text-xl font-bold text-[var(--text-main)] mb-1">Black</h3>
                  <div className="text-sm text-[var(--primary)]">Система на неделю</div>
                </div>
                <div className="text-right">
                  <div className="font-bold text-lg">490 ₽/мес</div>
                </div>
              </div>
              <ul className="text-sm text-[var(--text-muted)] mt-4 space-y-2">
                <li>• План на неделю</li>
                <li>• 2 варианта блюд</li>
                <li>• Рецепты и Список покупок</li>
                <li>• Витамины и совместимость</li>
              </ul>
            </div>

            {/* Gold */}
            <div 
              className={`p-6 rounded-2xl border-2 cursor-pointer transition-all ${activeStatus === 'gold' ? 'border-[var(--primary)] bg-[#FFFBEB]' : 'border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/50'}`}
              onClick={() => setActiveStatus('gold')}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <div className="text-xs font-bold text-[var(--text-main)] bg-[var(--primary)] px-2 py-1 rounded inline-block mb-2">Рекомендуемый</div>
                  <h3 className={`text-xl font-bold mb-1 ${activeStatus === 'gold' ? 'text-[var(--primary)]' : 'text-[var(--text-main)]'}`}>Gold</h3>
                  <div className={`text-sm ${activeStatus === 'gold' ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>Максимум персонализации</div>
                </div>
                <div className="text-right">
                  <div className={`font-bold text-lg ${activeStatus === 'gold' ? 'text-[var(--primary)]' : 'text-[var(--text-main)]'}`}>990 ₽/мес</div>
                </div>
              </div>
              <ul className={`text-sm mt-4 space-y-2 ${activeStatus === 'gold' ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>
                <li>• До 3 вариантов блюд на каждый приём пищи</li>
                <li>• Фото-анализ (Gemini) до 5 раз в день</li>
                <li>• Тренировки с видеоинструкциями</li>
                <li>• Умные отчёты Health Connect</li>
              </ul>
            </div>

            {/* Family Gold */}
            <div 
              className={`p-6 rounded-2xl border cursor-pointer transition-all ${activeStatus === 'family' ? 'border-red-500 bg-[#FEF2F2]' : 'border-[var(--border)] bg-[var(--surface)] hover:border-red-500/50'}`}
              onClick={() => setActiveStatus('family')}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className={`text-xl font-bold mb-1 ${activeStatus === 'family' ? 'text-red-900' : 'text-[var(--text-main)]'}`}>Family Gold</h3>
                  <div className={`text-sm ${activeStatus === 'family' ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>Для семьи — все возможности Gold каждому</div>
                </div>
                <div className="text-right">
                  <div className={`font-bold text-lg ${activeStatus === 'family' ? 'text-red-900' : 'text-[var(--text-main)]'}`}>от 1 680 ₽/мес</div>
                  <div className={`text-xs ${activeStatus === 'family' ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>990 ₽ + 690 ₽ за каждого</div>
                </div>
              </div>
              <div className={`mt-4 p-3 rounded-xl ${activeStatus === 'family' ? 'bg-red-50' : 'bg-white/5'} flex items-center justify-between`}>
                <span className={`text-sm font-medium ${activeStatus === 'family' ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>Участников:</span>
                <div className="flex items-center gap-3">
                  <button onClick={(e) => { e.stopPropagation(); setFamilyCount(Math.max(2, familyCount - 1)); }} className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-lg ${activeStatus === 'family' ? 'bg-red-200 text-[var(--primary)]' : 'bg-white/10 text-[var(--text-main)]'}`}>−</button>
                  <span className={`text-lg font-bold min-w-[2ch] text-center ${activeStatus === 'family' ? 'text-red-900' : 'text-[var(--text-main)]'}`}>{familyCount}</span>
                  <button onClick={(e) => { e.stopPropagation(); setFamilyCount(Math.min(5, familyCount + 1)); }} className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-lg ${activeStatus === 'family' ? 'bg-red-200 text-[var(--primary)]' : 'bg-white/10 text-[var(--text-main)]'}`}>+</button>
                </div>
                <span className={`text-sm font-bold ${activeStatus === 'family' ? 'text-red-900' : 'text-[var(--text-main)]'}`}>{990 + (familyCount - 1) * 690} ₽/мес</span>
              </div>
              <ul className={`text-sm mt-4 space-y-2 ${activeStatus === 'family' ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'}`}>
                <li>• Первый участник — 990 ₽ (полный Gold)</li>
                <li>• Каждый следующий — 690 ₽/мес</li>
                <li>• Общий список покупок для всей семьи</li>
                <li>• Добавление участников через код в приложении</li>
              </ul>
            </div>
          </div>
          
          <div className="mt-12 text-left bg-[var(--surface)] p-8 rounded-[32px] border border-[var(--border)]">
            <h3 className="text-2xl font-bold mb-6 text-[var(--text-main)]">Что произойдёт после оплаты</h3>
            <div className="space-y-6">
              <div className="flex gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-white/10 flex items-center justify-center font-bold text-[var(--primary)]">1</div>
                <div>
                  <div className="font-bold text-[var(--text-main)]">Ты переходишь к оплате</div>
                  <div className="text-sm text-[var(--text-muted)]">Открывается безопасная форма оплаты ЮKassa.</div>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-white/10 flex items-center justify-center font-bold text-[var(--primary)]">2</div>
                <div>
                  <div className="font-bold text-[var(--text-main)]">Статус активируется</div>
                  <div className="text-sm text-[var(--text-muted)]">После успешной оплаты ejeweeka получает подтверждение.</div>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-shrink-0 w-8 h-8 rounded-full bg-white/10 flex items-center justify-center font-bold text-[var(--primary)]">3</div>
                <div>
                  <div className="font-bold text-[var(--text-main)]">Возвращаешься в приложение</div>
                  <div className="text-sm text-[var(--text-muted)]">Статус будет привязан к твоему профилю. Если потребуется восстановление, используй форму на сайте.</div>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-8 border-t border-[var(--border)]">
              <label className="block mb-4 text-sm text-[var(--text-muted)]">
                Твой ID (опционально, для привязки статуса):
                <input 
                  type="text" 
                  value={uuid} 
                  onChange={(e) => setUuid(e.target.value)}
                  placeholder="Например: a1b2c3d4..." 
                  className="mt-1 block w-full p-3 rounded-xl bg-[var(--surface)] border border-[var(--border)] text-[var(--text-main)] focus:border-[var(--primary)] outline-none transition-colors"
                />
              </label>
              
              <label className="flex items-start gap-3 cursor-pointer">
                <input 
                  type="checkbox" 
                  checked={agreeTerms}
                  onChange={(e) => setAgreeTerms(e.target.checked)}
                  className="mt-1 w-5 h-5 accent-[var(--primary)]"
                />
                <span className="text-sm text-[var(--text-muted)] leading-tight">
                  Я принимаю условия оферты, политики конфиденциальности и условия статуса. Согласен на разовую оплату выбранного периода.
                </span>
              </label>
              
              <button 
                onClick={handleCheckout} 
                disabled={isLoading || activeStatus === 'white'}
                className="mt-8 btn-primary-eje px-8 py-4 text-lg w-full flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? (
                  <span className="flex items-center gap-3">
                    <div className="w-5 h-5 border-2 border-black border-t-transparent rounded-full animate-spin"></div>
                    Обработка...
                  </span>
                ) : (
                  activeStatus === 'white' ? "Статус доступен в приложении" : `Выбрать ${activeStatus.toUpperCase()}`
                )}
              </button>
            </div>
          </div>

        </div>
      </section>
    </div>
  );
}
