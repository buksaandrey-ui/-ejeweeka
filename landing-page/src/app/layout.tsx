import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin", "cyrillic"],
});

export const viewport: Viewport = {
  themeColor: "#F9FAFB",
};

export const metadata: Metadata = {
  title: "ejeweeka — premium wellness intelligence app",
  description: "Умный наставник, который учитывает цель, город, бюджет, ограничения, витамины и вкусы — чтобы собрать план, который реально можно соблюдать.",
  icons: {
    icon: [
      { url: "/favicon.ico" },
      { url: "/favicon-16.png", sizes: "16x16", type: "image/png" },
      { url: "/favicon-32.png", sizes: "32x32", type: "image/png" },
    ],
    apple: [
      { url: "/apple-touch-icon.png", sizes: "180x180" }
    ],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="ru"
      data-theme="light"
      className={`${inter.variable} h-full antialiased theme-light`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
