#!/usr/bin/env bash

echo "=========================================="
echo "Adding /app view to Academic Co-Pilot"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Step 1: Installing dependencies..."
echo ""
# Install date-fns for date manipulation
npm install date-fns

echo ""
echo "Step 2: Creating /app route directory..."
mkdir -p app/app

echo ""
echo "Step 3: Creating components..."
mkdir -p components/app

# Create AppHeader component
cat << 'EOF' > components/app/AppHeader.tsx
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
EOF

echo "✓ Created components/app/AppHeader.tsx"

# Create Calendar component
cat << 'EOF' > components/app/Calendar.tsx
'use client';

import React, { useState } from 'react';
import { 
  format, 
  startOfMonth, 
  endOfMonth, 
  startOfWeek, 
  endOfWeek, 
  addDays, 
  addMonths, 
  subMonths,
  isSameMonth,
  isSameDay,
  parseISO
} from 'date-fns';

interface CalendarEvent {
  id: number;
  title: string;
  date: string;
}

interface CalendarProps {
  events: CalendarEvent[];
}

export default function Calendar({ events }: CalendarProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date(2025, 9, 1)); // October 2025

  const nextMonth = () => {
    const next = addMonths(currentMonth, 1);
    // Don't go past October 2026
    if (next <= new Date(2026, 9, 31)) {
      setCurrentMonth(next);
    }
  };

  const prevMonth = () => {
    const prev = subMonths(currentMonth, 1);
    // Don't go before October 2025
    if (prev >= new Date(2025, 9, 1)) {
      setCurrentMonth(prev);
    }
  };

  const renderHeader = () => {
    return (
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-neutral-900">
          {format(currentMonth, 'MMMM yyyy')}
        </h2>
        <div className="flex gap-2">
          <button
            onClick={prevMonth}
            disabled={currentMonth <= new Date(2025, 9, 1)}
            className="px-4 py-2 bg-neutral-100 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium hover:bg-neutral-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Previous
          </button>
          <button
            onClick={nextMonth}
            disabled={currentMonth >= new Date(2026, 9, 1)}
            className="px-4 py-2 bg-neutral-100 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium hover:bg-neutral-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            Next
          </button>
        </div>
      </div>
    );
  };

  const renderDays = () => {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return (
      <div className="grid grid-cols-7 gap-2 mb-2">
        {days.map((day) => (
          <div key={day} className="text-center text-sm font-semibold text-neutral-600 py-2">
            {day}
          </div>
        ))}
      </div>
    );
  };

  const renderCells = () => {
    const monthStart = startOfMonth(currentMonth);
    const monthEnd = endOfMonth(monthStart);
    const startDate = startOfWeek(monthStart);
    const endDate = endOfWeek(monthEnd);

    const rows = [];
    let days = [];
    let day = startDate;

    while (day <= endDate) {
      for (let i = 0; i < 7; i++) {
        const formattedDate = format(day, 'd');
        const cloneDay = day;
        const dayEvents = events.filter((event) =>
          isSameDay(parseISO(event.date), cloneDay)
        );

        days.push(
          <div
            key={day.toString()}
            className={`min-h-[100px] p-2 border border-neutral-200 rounded-lg ${
              !isSameMonth(day, monthStart)
                ? 'bg-neutral-50 text-neutral-400'
                : 'bg-white hover:bg-neutral-50'
            } transition-colors`}
          >
            <div className="font-semibold text-sm mb-1">{formattedDate}</div>
            <div className="space-y-1">
              {dayEvents.map((event) => (
                <div
                  key={event.id}
                  className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded truncate"
                  title={event.title}
                >
                  {event.title}
                </div>
              ))}
            </div>
          </div>
        );
        day = addDays(day, 1);
      }
      rows.push(
        <div key={day.toString()} className="grid grid-cols-7 gap-2">
          {days}
        </div>
      );
      days = [];
    }

    return <div className="space-y-2">{rows}</div>;
  };

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm">
      {renderHeader()}
      {renderDays()}
      {renderCells()}
    </div>
  );
}
EOF

echo "✓ Created components/app/Calendar.tsx"

# Create SyllabusUpload component
cat << 'EOF' > components/app/SyllabusUpload.tsx
'use client';

import React, { useState, useRef } from 'react';

interface UploadedFile {
  name: string;
  size: number;
}

export default function SyllabusUpload() {
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([]);
  const [pastedText, setPastedText] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    const files = Array.from(e.dataTransfer.files);
    processFiles(files);
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files);
      processFiles(files);
    }
  };

  const processFiles = (files: File[]) => {
    const validFiles = files.filter((file) => {
      const validTypes = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain',
      ];
      return validTypes.includes(file.type) || 
             file.name.endsWith('.pdf') || 
             file.name.endsWith('.doc') || 
             file.name.endsWith('.docx') || 
             file.name.endsWith('.txt');
    });

    const newFiles = validFiles.map((file) => ({
      name: file.name,
      size: file.size,
    }));

    setUploadedFiles((prev) => [...prev, ...newFiles]);
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const removeFile = (index: number) => {
    setUploadedFiles((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-8 shadow-sm space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-neutral-900 mb-2">
          Upload your syllabi
        </h2>
        <p className="text-neutral-600">
          Drop your syllabi here, and we'll later turn them into a calendar of deadlines.
        </p>
      </div>

      {/* File Drop Zone */}
      <div
        onDragEnter={handleDragEnter}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
        className={`border-2 border-dashed rounded-xl p-12 text-center cursor-pointer transition-all ${
          isDragging
            ? 'border-blue-400 bg-blue-50'
            : 'border-neutral-300 bg-neutral-50 hover:border-neutral-400 hover:bg-neutral-100'
        }`}
      >
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept=".pdf,.doc,.docx,.txt"
          onChange={handleFileSelect}
          className="hidden"
        />
        <div className="space-y-2">
          <div className="text-4xl">📄</div>
          <p className="text-neutral-700 font-medium">
            Drop files here or click to browse
          </p>
          <p className="text-sm text-neutral-500">
            Supports PDF, DOC, DOCX, TXT
          </p>
        </div>
      </div>

      {/* Uploaded Files List */}
      {uploadedFiles.length > 0 && (
        <div className="space-y-2">
          <h3 className="font-semibold text-neutral-900">Uploaded Files</h3>
          <div className="space-y-2">
            {uploadedFiles.map((file, index) => (
              <div
                key={index}
                className="flex items-center justify-between bg-neutral-50 border border-neutral-200 rounded-lg p-3"
              >
                <div className="flex items-center gap-3">
                  <div className="text-2xl">📄</div>
                  <div>
                    <p className="text-sm font-medium text-neutral-900">
                      {file.name}
                    </p>
                    <p className="text-xs text-neutral-500">
                      {formatFileSize(file.size)}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => removeFile(index)}
                  className="text-neutral-400 hover:text-red-600 transition-colors"
                >
                  ✕
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Text Area */}
      <div className="space-y-2">
        <h3 className="font-semibold text-neutral-900">Or paste syllabus text</h3>
        <textarea
          value={pastedText}
          onChange={(e) => setPastedText(e.target.value)}
          placeholder="Paste your syllabus text here..."
          className="w-full h-32 px-4 py-3 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 resize-none"
        />
        {pastedText && (
          <p className="text-sm text-neutral-500">
            {pastedText.length} characters
          </p>
        )}
      </div>
    </div>
  );
}
EOF

echo "✓ Created components/app/SyllabusUpload.tsx"

# Create the /app page
cat << 'EOF' > app/app/page.tsx
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
EOF

echo "✓ Created app/app/page.tsx"

# Update the landing page Header to link SIGN IN to /app
cat << 'EOF' > components/Header.tsx
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
EOF

echo "✓ Updated components/Header.tsx (SIGN IN now links to /app)"

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Installed date-fns for calendar date handling"
echo "  ✓ Created /app route at app/app/page.tsx"
echo "  ✓ Created AppHeader component"
echo "  ✓ Created Calendar component (Oct 2025 - Oct 2026)"
echo "  ✓ Created SyllabusUpload component"
echo "  ✓ Updated landing Header to link to /app"
echo ""
echo "To see your changes:"
echo "  npm run dev"
echo ""
echo "Then visit:"
echo "  http://localhost:3000 (landing page)"
echo "  http://localhost:3000/app (new app view)"
echo ""
