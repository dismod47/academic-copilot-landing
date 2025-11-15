'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export default function AppHeader() {
  const [user, setUser] = useState<{ id: string; email: string; name?: string } | null>(null);
  const router = useRouter();

  useEffect(() => {
    // Check if user is signed in
    fetch('/api/auth/session')
      .then((res) => res.json())
      .then((data) => {
        if (data.user) {
          setUser(data.user);
        } else {
          // Not authenticated, redirect to home
          router.push('/');
        }
      })
      .catch((err) => {
        console.error('Failed to check session:', err);
        router.push('/');
      });
  }, [router]);

  const handleSignOut = async () => {
    try {
      await fetch('/api/auth/signout', { method: 'POST' });
      router.push('/');
      router.refresh();
    } catch (error) {
      console.error('Failed to sign out:', error);
    }
  };

  const getUserInitials = (email: string, name?: string) => {
    if (name) {
      const parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return name[0].toUpperCase();
    }
    return email[0].toUpperCase();
  };

  if (!user) {
    return null; // Will redirect, so don't render
  }

  return (
    <header className="w-full bg-neutral-100 border-b border-neutral-200">
      <div className="max-w-6xl mx-auto px-6 py-3">
        <div className="flex justify-between items-center">
          <Link href="/" className="font-semibold text-neutral-900 hover:text-neutral-700">
            SyllaSync
          </Link>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-sm font-medium text-white">
                {getUserInitials(user.email, user.name)}
              </div>
              <span className="text-sm text-neutral-700">
                {user.name || user.email}
              </span>
            </div>
            <button
              onClick={handleSignOut}
              className="px-4 py-2 bg-neutral-50 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium shadow-sm hover:bg-white transition-colors"
            >
              Sign Out
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
