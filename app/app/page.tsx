'use client';

import React, { useState } from 'react';
import AppHeader from '@/components/app/AppHeader';
import Calendar from '@/components/app/Calendar';
import SyllabusUpload from '@/components/app/SyllabusUpload';

export default function AppPage() {
  const [events, setEvents] = useState([
    { id: 1, title: 'Example: Homework 1 Due', date: '2025-10-03' },
    { id: 2, title: 'Midterm Exam', date: '2025-10-15' },
    { id: 3, title: 'Project Proposal Due', date: '2025-10-22' },
    { id: 4, title: 'Reading Assignment', date: '2025-10-10' },
  ]);

  return (
    <div className="min-h-screen bg-neutral-50">
      <AppHeader />
      <main className="max-w-6xl mx-auto px-6 py-8 space-y-8">
        <Calendar events={events} />
        <SyllabusUpload />
      </main>
    </div>
  );
}
