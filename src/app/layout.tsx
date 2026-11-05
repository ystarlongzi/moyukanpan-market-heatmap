import type { Metadata } from "next";
import { Toaster } from "sonner";

import "./globals.css";

const title = "摸鱼看盘 · A 股云图";
const description =
  "按行业和流通市值查看 A 股个股涨跌，支持主要指数、行业筛选、自选股和多周期切换。";

export const metadata: Metadata = {
  title,
  description,
  keywords: ["摸鱼看盘", "A 股云图", "股票热力图", "行业板块", "自选股"],
  icons: {
    icon: "/icon.svg",
    shortcut: "/icon.svg",
  },
  openGraph: {
    title,
    description,
    siteName: "摸鱼看盘",
    type: "website",
  },
  twitter: {
    card: "summary",
    title,
    description,
  },
};

const themeInitScript = `
  try {
    const displayMode = window.localStorage.getItem("heatmap-display-mode");
    const isDark = displayMode !== "light";
    document.documentElement.classList.toggle("dark", isDark);
    document.documentElement.style.colorScheme = isDark ? "dark" : "light";
  } catch {
    document.documentElement.classList.add("dark");
    document.documentElement.style.colorScheme = "dark";
  }
  try {
    if (window.location.pathname === "/") {
      document.documentElement.classList.add("heatmap-page-active");
    }
  } catch {}
`;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="zh-CN"
      className="min-h-dvh antialiased dark"
      suppressHydrationWarning
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInitScript }} />
      </head>
      <body className="flex min-h-dvh flex-col">
        {children}
        <Toaster richColors position="top-center" />
      </body>
    </html>
  );
}
