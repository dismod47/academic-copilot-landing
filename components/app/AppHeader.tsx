import React from 'react';
import Link from 'next/link';

export default function AppHeader() {
  return (
    <header className="w-full bg-neutral-100 border-b border-neutral-200">
      <div className="max-w-6xl mx-auto px-6 py-3">
        <div className="flex justify-between items-center">
          <Link href="/" className="font-semibold text-neutral-900 hover:text-neutral-700">
            Your Academic Co-Pilot
          </Link>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-neutral-300 rounded-full flex items-center justify-center text-sm font-medium text-neutral-700">
                JS
              </div>
              <span className="text-sm text-neutral-700">Signed in</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}
