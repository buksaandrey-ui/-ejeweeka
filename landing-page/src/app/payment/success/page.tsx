"use client";

import React, { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";

function PaymentSuccessContent() {
  const searchParams = useSearchParams();
  const paymentId = searchParams?.get("payment_id");
  const [status, setStatus] = useState<"loading" | "success" | "pending" | "failed">("loading");

  useEffect(() => {
    const checkStatus = setTimeout(() => {
      if (paymentId) {
        setStatus("success");
      } else {
        setStatus("failed");
      }
    }, 2000);
    
    return () => clearTimeout(checkStatus);
  }, [paymentId]);

  return (
    <div className="max-w-md w-full bg-[var(--surface)] p-8 rounded-[32px] border border-[var(--border)] text-center">
      {status === "loading" && (
        <>
          <div className="w-16 h-16 border-4 border-white/10 border-t-[#F5922B] rounded-full animate-spin mx-auto mb-6"></div>
          <h1 className="text-2xl font-bold text-white mb-2">Проверяем оплату</h1>
          <p className="text-gray-400">Это займёт несколько секунд. После подтверждения статус активируется автоматически.</p>
        </>
      )}
      
      {status === "success" && (
        <>
          <div className="w-16 h-16 bg-green-500/20 text-green-500 rounded-full flex items-center justify-center text-3xl mx-auto mb-6">✓</div>
          <h1 className="text-2xl font-bold text-white mb-2">Готово. Статус активирован.</h1>
          <p className="text-gray-400 mb-8">Теперь ты можешь вернуться в приложение Health Code. Новые возможности уже доступны.</p>
          <Link href="/" className="btn-primary-eje px-8 py-3 w-full block">Открыть Health Code</Link>
        </>
      )}

      {status === "pending" && (
        <>
          <div className="w-16 h-16 bg-yellow-500/20 text-yellow-500 rounded-full flex items-center justify-center text-3xl mx-auto mb-6">⏳</div>
          <h1 className="text-2xl font-bold text-white mb-2">Оплата принята</h1>
          <p className="text-gray-400 mb-8">Статус активируется. Обновите приложение через несколько секунд.</p>
          <Link href="/" className="btn-primary-eje px-8 py-3 w-full block">Вернуться на главную</Link>
        </>
      )}

      {status === "failed" && (
        <>
          <div className="w-16 h-16 bg-red-500/20 text-red-500 rounded-full flex items-center justify-center text-3xl mx-auto mb-6">✕</div>
          <h1 className="text-2xl font-bold text-white mb-2">Не удалось подтвердить</h1>
          <p className="text-gray-400 mb-8">Попробуйте ещё раз или напишите в поддержку.</p>
          <Link href="/subscribe" className="px-8 py-3 w-full block border border-white/20 rounded-xl text-white hover:bg-white/5 transition-colors">Вернуться к статусам</Link>
        </>
      )}
    </div>
  );
}

export default function PaymentSuccessPage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--text-main)] flex items-center justify-center p-6">
      <Suspense fallback={
        <div className="max-w-md w-full bg-[var(--surface)] p-8 rounded-[32px] border border-[var(--border)] text-center">
          <div className="w-16 h-16 border-4 border-white/10 border-t-[#F5922B] rounded-full animate-spin mx-auto mb-6"></div>
          <h1 className="text-2xl font-bold text-white mb-2">Загрузка...</h1>
        </div>
      }>
        <PaymentSuccessContent />
      </Suspense>
    </div>
  );
}

