"use client";

import React from "react";
import Link from "next/link";

export default function PaymentCancelPage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--text-main)] flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-[var(--surface)] p-8 rounded-[32px] border border-[var(--border)] text-center">
        <div className="w-16 h-16 bg-[var(--border)] text-[var(--text-muted)] rounded-full flex items-center justify-center text-3xl mx-auto mb-6">↩</div>
        <h1 className="text-2xl font-bold text-[var(--text-main)] mb-2">Оплата не завершена</h1>
        <p className="text-[var(--text-muted)] mb-8">Ты можешь вернуться к выбору статуса и попробовать ещё раз.</p>
        <Link href="/subscribe" className="px-8 py-3 w-full block border border-[var(--primary)] bg-[var(--primary)]/10 text-[var(--primary)] font-bold rounded-xl hover:bg-[var(--primary)]/20 transition-colors">Вернуться к статусам</Link>
      </div>
    </div>
  );
}
