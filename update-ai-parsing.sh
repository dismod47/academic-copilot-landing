#!/usr/bin/env bash

echo "=========================================="
echo "Adding AI Syllabus Parsing to /app"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Step 1: Installing dependencies..."
echo ""
npm install @google/generative-ai

echo ""
echo "Step 2: Creating API route..."
mkdir -p app/api/parse-syllabus

# Create the API route handler
cat << 'EOF' > app/api/parse-syllabus/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.VERTEX_API_KEY || '');

interface Event {
  title: string;
  date: string;
  description?: string;
}

export async function POST(request: NextRequest) {
  try {
    const { syllabusText } = await request.json();

    if (!syllabusText || syllabusText.trim().length === 0) {
      return NextResponse.json(
        { error: 'No syllabus text provided' },
        { status: 400 }
      );
    }

    if (!process.env.VERTEX_API_KEY) {
      return NextResponse.json(
        { error: 'API key not configured' },
        { status: 500 }
      );
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `You are a syllabus parser. Extract ALL dated events from the following course syllabus.

For each event (exam, homework, quiz, project, major reading, assignment, etc.), extract:
- title: A clear, concise title for the event
- date: The date in YYYY-MM-DD format
- description: Optional brief description

Return ONLY a valid JSON array of events. If no events can be found, return an empty array [].

Example format:
[
  {
    "title": "Homework 1 Due",
    "date": "2025-10-15",
    "description": "Chapter 1-3 problems"
  },
  {
    "title": "Midterm Exam",
    "date": "2025-11-05"
  }
]

IMPORTANT: 
- Only extract events with clear, specific dates
- Convert all dates to YYYY-MM-DD format
- If a date is relative (like "Week 3"), try to calculate the actual date based on semester context
- Do NOT include vague or undated items
- Return ONLY the JSON array, no other text

Syllabus:
${syllabusText}`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Try to extract JSON from the response
    let events: Event[] = [];
    try {
      // Remove markdown code blocks if present
      const cleanedText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      events = JSON.parse(cleanedText);
      
      if (!Array.isArray(events)) {
        throw new Error('Response is not an array');
      }

      // Validate event structure
      events = events.filter(event => 
        event.title && 
        event.date && 
        /^\d{4}-\d{2}-\d{2}$/.test(event.date)
      );
    } catch (parseError) {
      console.error('Failed to parse AI response:', text);
      return NextResponse.json(
        { error: 'Could not parse events from syllabus. Please ensure the syllabus contains clear dates.' },
        { status: 400 }
      );
    }

    if (events.length === 0) {
      return NextResponse.json(
        { error: 'No dated events found in the syllabus. Please check that dates are clearly specified.' },
        { status: 400 }
      );
    }

    return NextResponse.json({ events });
  } catch (error) {
    console.error('Error parsing syllabus:', error);
    return NextResponse.json(
      { error: 'Failed to parse syllabus. Please try again.' },
      { status: 500 }
    );
  }
}
EOF

echo "✓ Created app/api/parse-syllabus/route.ts"

echo ""
echo "Step 3: Creating EventsWidget component..."

cat << 'EOF' > components/app/EventsWidget.tsx
'use client';

import React from 'react';
import { format, parseISO } from 'date-fns';

interface Event {
  id: number;
  title: string;
  date: string;
  description?: string;
}

interface EventsWidgetProps {
  events: Event[];
  onClose: () => void;
}

export default function EventsWidget({ events, onClose }: EventsWidgetProps) {
  if (events.length === 0) return null;

  return (
    <div className="fixed bottom-6 right-6 w-96 max-w-[calc(100vw-3rem)] bg-white rounded-xl border-2 border-green-300 shadow-2xl z-50 overflow-hidden">
      <div className="bg-green-50 border-b border-green-200 px-4 py-3 flex items-center justify-between">
        <h3 className="font-semibold text-green-900 flex items-center gap-2">
          <span className="text-xl">✓</span>
          New events added ({events.length})
        </h3>
        <button
          onClick={onClose}
          className="text-green-700 hover:text-green-900 text-xl leading-none"
        >
          ✕
        </button>
      </div>
      <div className="max-h-96 overflow-y-auto p-4 space-y-3">
        {events.map((event) => (
          <div
            key={event.id}
            className="bg-neutral-50 border border-neutral-200 rounded-lg p-3"
          >
            <div className="flex items-start justify-between gap-2">
              <div className="flex-1">
                <p className="font-medium text-neutral-900 text-sm">
                  {event.title}
                </p>
                <p className="text-xs text-neutral-600 mt-1">
                  {format(parseISO(event.date), 'MMMM d, yyyy')}
                </p>
                {event.description && (
                  <p className="text-xs text-neutral-500 mt-1">
                    {event.description}
                  </p>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
EOF

echo "✓ Created components/app/EventsWidget.tsx"

echo ""
echo "Step 4: Updating SyllabusUpload component..."

cat << 'EOF' > components/app/SyllabusUpload.tsx
'use client';

import React, { useState, useRef } from 'react';

interface UploadedFile {
  name: string;
  size: number;
}

interface SyllabusUploadProps {
  onEventsGenerated: (events: any[]) => void;
}

export default function SyllabusUpload({ onEventsGenerated }: SyllabusUploadProps) {
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([]);
  const [pastedText, setPastedText] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
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

  const handleGenerateFromSyllabus = async () => {
    if (!pastedText.trim()) {
      setError('Please paste syllabus text first');
      return;
    }

    setIsLoading(true);
    setError('');

    try {
      const response = await fetch('/api/parse-syllabus', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ syllabusText: pastedText }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to parse syllabus');
      }

      if (data.events && data.events.length > 0) {
        onEventsGenerated(data.events);
        setError('');
      } else {
        setError('No events found in the syllabus');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to parse syllabus. Please try again.');
    } finally {
      setIsLoading(false);
    }
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
      <div className="space-y-3">
        <h3 className="font-semibold text-neutral-900">Or paste syllabus text</h3>
        <textarea
          value={pastedText}
          onChange={(e) => {
            setPastedText(e.target.value);
            setError('');
          }}
          placeholder="Paste your syllabus text here..."
          className="w-full h-32 px-4 py-3 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 resize-none"
          disabled={isLoading}
        />
        {pastedText && (
          <p className="text-sm text-neutral-500">
            {pastedText.length} characters
          </p>
        )}
        
        {/* Generate Button */}
        <button
          onClick={handleGenerateFromSyllabus}
          disabled={isLoading || !pastedText.trim()}
          className="w-full px-6 py-3 bg-blue-500 text-white rounded-lg font-medium shadow-md hover:bg-blue-600 disabled:bg-neutral-300 disabled:cursor-not-allowed transition-colors"
        >
          {isLoading ? 'Parsing syllabus...' : 'Generate from syllabus'}
        </button>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-3">
            <p className="text-sm text-red-800">{error}</p>
          </div>
        )}
      </div>
    </div>
  );
}
EOF

echo "✓ Updated components/app/SyllabusUpload.tsx"

echo ""
echo "Step 5: Updating /app page..."

cat << 'EOF' > app/app/page.tsx
'use client';

import React, { useState } from 'react';
import AppHeader from '@/components/app/AppHeader';
import Calendar from '@/components/app/Calendar';
import SyllabusUpload from '@/components/app/SyllabusUpload';
import EventsWidget from '@/components/app/EventsWidget';

interface CalendarEvent {
  id: number;
  title: string;
  date: string;
  description?: string;
}

export default function AppPage() {
  const [events, setEvents] = useState<CalendarEvent[]>([
    { id: 1, title: 'Example: Homework 1 Due', date: '2025-10-03' },
    { id: 2, title: 'Midterm Exam', date: '2025-10-15' },
    { id: 3, title: 'Project Proposal Due', date: '2025-10-22' },
    { id: 4, title: 'Reading Assignment', date: '2025-10-10' },
  ]);

  const [newEvents, setNewEvents] = useState<CalendarEvent[]>([]);
  const [showWidget, setShowWidget] = useState(false);

  const handleEventsGenerated = (generatedEvents: any[]) => {
    const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
    
    const eventsWithIds = generatedEvents.map((event, index) => ({
      id: maxId + index + 1,
      title: event.title,
      date: event.date,
      description: event.description,
    }));

    setEvents((prev) => [...prev, ...eventsWithIds]);
    setNewEvents(eventsWithIds);
    setShowWidget(true);
  };

  const handleCloseWidget = () => {
    setShowWidget(false);
    setNewEvents([]);
  };

  return (
    <div className="min-h-screen bg-neutral-50">
      <AppHeader />
      <main className="max-w-6xl mx-auto px-6 py-8 space-y-8">
        <Calendar events={events} />
        <SyllabusUpload onEventsGenerated={handleEventsGenerated} />
      </main>

      {showWidget && (
        <EventsWidget events={newEvents} onClose={handleCloseWidget} />
      )}
    </div>
  );
}
EOF

echo "✓ Updated app/app/page.tsx"

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Installed @google/generative-ai"
echo "  ✓ Created API route: /api/parse-syllabus"
echo "  ✓ Created EventsWidget component"
echo "  ✓ Updated SyllabusUpload with AI parsing"
echo "  ✓ Updated /app page with event handling"
echo ""
echo "Make sure your .env.local contains:"
echo "  VERTEX_API_KEY=your_actual_key"
echo ""
echo "To test:"
echo "  npm run dev"
echo "  Visit http://localhost:3000/app"
echo "  Paste a syllabus and click 'Generate from syllabus'"
echo ""
