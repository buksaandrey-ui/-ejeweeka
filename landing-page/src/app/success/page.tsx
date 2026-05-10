'use client';

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';

function SuccessContent() {
  const searchParams = useSearchParams();
  const paymentId = searchParams.get('payment_id');
  
  const [code, setCode] = useState<string | null>(null);
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading');

  useEffect(() => {
    if (!paymentId) {
      setStatus('error');
      return;
    }

    let intervalId: NodeJS.Timeout;
    let attempts = 0;
    const maxAttempts = 20; // Poll for about 40 seconds

    const pollPaymentStatus = async () => {
      try {
        const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
        const res = await fetch(`${backendUrl}/api/v1/subscription/payments/${paymentId}/code`);
        
        if (res.ok) {
          const data = await res.json();
          if (data.status === 'success' && data.code) {
            setCode(data.code);
            setStatus('success');
            clearInterval(intervalId);
            return;
          }
        }
      } catch (err) {
        console.error("Error polling payment status:", err);
      }
      
      attempts++;
      if (attempts >= maxAttempts) {
        clearInterval(intervalId);
        setStatus('error');
      }
    };

    // Poll every 2 seconds
    intervalId = setInterval(pollPaymentStatus, 2000);
    // Initial fetch
    pollPaymentStatus();

    return () => clearInterval(intervalId);
  }, [paymentId]);

  return (
    <div className="min-h-screen bg-[var(--bg)] text-white flex flex-col items-center justify-center p-6">
      <div className="w-full max-w-md bg-[var(--surface)] border border-[var(--border)] rounded-3xl p-8 text-center shadow-2xl">
        <div className="w-20 h-20 bg-green-500/20 text-green-400 rounded-full flex items-center justify-center mx-auto mb-6">
          <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        
        <h1 className="text-3xl font-extrabold mb-4">Оплата прошла успешно!</h1>
        <p className="text-[#A1A1A6] mb-8">
          Твой индивидуальный алгоритм активирован. Остался последний шаг — запустить приложение.
        </p>

        {status === 'loading' && (
          <div className="py-6">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#F5922B] mx-auto mb-4"></div>
            <p className="text-[#F5922B] font-medium animate-pulse">Генерируем твой Magic Code...</p>
          </div>
        )}

        {status === 'success' && code && (
          <div className="mb-8">
            <div className="text-sm text-[#A1A1A6] mb-2 uppercase tracking-wider font-bold">Твой код доступа</div>
            <div className="bg-[#0A0A0A] border border-[#F5922B]/30 rounded-2xl py-6 px-4">
              <span className="text-4xl font-black text-[#F5922B] tracking-[0.2em]">{code}</span>
            </div>
            <p className="text-sm text-[#A1A1A6] mt-4">
              Скопируйте этот код и введите его при первом входе в мобильное приложение Health Code.
            </p>
          </div>
        )}

        {status === 'error' && (
          <div className="py-6 bg-red-500/10 border border-red-500/20 rounded-2xl mb-8">
            <p className="text-red-400">Не удалось получить код. Пожалуйста, проверьте почту, мы продублировали его туда.</p>
          </div>
        )}

        <button 
          className="w-full bg-[#F5922B] hover:bg-[#E08120] text-black font-bold py-4 px-6 rounded-2xl transition-all"
          onClick={() => window.location.href = 'https://apps.apple.com/app/health-code'}
        >
          Скачать в App Store
        </button>
      </div>
    </div>
  );
}

export default function SuccessPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[var(--bg)] text-white flex items-center justify-center">Loading...</div>}>
      <SuccessContent />
    </Suspense>
  );
}
