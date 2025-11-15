import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Your Academic Co-Pilot',
  description: 'Turn messy syllabi into a clear, AI-powered plan for your semester.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="bg-neutral-50 text-neutral-900">{children}</body>
    </html>
  )
}
