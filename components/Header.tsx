'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AuthModal from './AuthModal';

export default function Header() {
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [authMode, setAuthMode] = useState<'signup' | 'signin'>('signin');
  const [user, setUser] = useState<{ id: string; email: string; name?: string } | null>(null);
  const router = useRouter();

  useEffect(() => {
    // Check if user is already signed in
    fetch('/api/auth/session')
      .then((res) => res.json())
      .then((data) => {
        if (data.user) {
          setUser(data.user);
        }
      })
      .catch((err) => console.error('Failed to check session:', err));
  }, []);

  const handleAuthSuccess = (userData: { id: string; email: string; name?: string }) => {
    setUser(userData);
    setShowAuthModal(false);
    router.push('/app');
    router.refresh();
  };

  const handleSignOut = async () => {
    try {
      await fetch('/api/auth/signout', { method: 'POST' });
      setUser(null);
      router.push('/');
      router.refresh();
    } catch (error) {
      console.error('Failed to sign out:', error);
    }
  };

  return (
    <>
      <header className="w-full bg-neutral-100 border-b border-neutral-200">
        <div className="max-w-6xl mx-auto px-6 py-3">
          <div className="flex justify-between items-center">
            <div className="font-semibold text-neutral-900">
              Your Academic Co-Pilot
            </div>
            <div className="flex items-center gap-4">
              {user ? (
                <>
                  <span className="text-sm text-neutral-700">
                    {user.name || user.email}
                  </span>
                  <button
                    onClick={() => router.push('/app')}
                    className="px-4 py-2 bg-blue-500 text-white rounded-lg text-sm font-medium shadow-sm hover:bg-blue-600 transition-colors"
                  >
                    Go to App
                  </button>
                  <button
                    onClick={handleSignOut}
                    className="px-4 py-2 bg-neutral-50 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium shadow-sm hover:bg-white transition-colors"
                  >
                    Sign Out
                  </button>
                </>
              ) : (
                <>
                  <span className="text-sm text-neutral-700 cursor-pointer hover:text-neutral-900">
                    FREE TRIAL
                  </span>
                  <button
                    onClick={() => {
                      setAuthMode('signup');
                      setShowAuthModal(true);
                    }}
                    className="px-4 py-2 bg-neutral-50 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium shadow-sm hover:bg-white transition-colors"
                  >
                    SIGN UP
                  </button>
                  <button
                    onClick={() => {
                      setAuthMode('signin');
                      setShowAuthModal(true);
                    }}
                    className="px-4 py-2 bg-blue-500 text-white rounded-lg text-sm font-medium shadow-sm hover:bg-blue-600 transition-colors"
                  >
                    SIGN IN
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      </header>

      <AuthModal
        isOpen={showAuthModal}
        mode={authMode}
        onClose={() => setShowAuthModal(false)}
        onSwitchMode={() =>
          setAuthMode(authMode === 'signup' ? 'signin' : 'signup')
        }
        onSuccess={handleAuthSuccess}
      />
    </>
  );
}
