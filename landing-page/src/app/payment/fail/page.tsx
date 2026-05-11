"use client";

import React from "react";
import Link from "next/link";

export default function PaymentFailPage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-[var(--text-main)] flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-[var(--surface)] p-8 rounded-[32px] border border-[var(--border)] text-center">
        <div className="w-16 h-16 bg-red-500/20 text-red-500 rounded-full flex items-center justify-center text-3xl mx-auto mb-6">✕</div>
        <h1 className="text-2xl font-bold text-[var(--text-main)] mb-2">Платёж не прошёл</h1>
        <p className="text-[var(--text-muted)] mb-8">Деньги не списаны или платёж был отклонён. Попробуй другой способ оплаты.</p>
        <Link href="/subscribe" className="px-8 py-3 w-full block border border-red-500/50 bg-red-500/10 text-red-400 font-bold rounded-xl hover:bg-red-500/20 transition-colors">Попробовать снова</Link>
      </div>
    </div>
  );
}
