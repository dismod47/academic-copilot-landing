import React from 'react';
import Link from 'next/link';

export default function Header() {
  return (
    <header className="w-full bg-neutral-100 border-b border-neutral-200">
      <div className="max-w-6xl mx-auto px-6 py-3">
        <div className="flex justify-between items-center">
          <div className="font-semibold text-neutral-900">
            Your Academic Co-Pilot
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-neutral-700 cursor-pointer hover:text-neutral-900">
              FREE TRIAL
            </span>
            <Link href="/app">
              <button className="px-4 py-2 bg-neutral-50 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium shadow-sm hover:bg-white transition-colors">
                SIGN IN
              </button>
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
