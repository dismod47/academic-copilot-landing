#!/usr/bin/env bash

echo "=========================================="
echo "Adding Grade Planner to /app"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Creating Grade Planner component..."
echo ""

# Create GradePlanner component
cat << 'EOF' > components/app/GradePlanner.tsx
'use client';

import React, { useState } from 'react';

interface GradeCategory {
  id: string;
  name: string;
  weight: number;
  currentScore: number;
  isCompleted: boolean;
}

export default function GradePlanner() {
  const [courseName, setCourseName] = useState('');
  const [targetGrade, setTargetGrade] = useState<number>(90);
  const [categories, setCategories] = useState<GradeCategory[]>([
    {
      id: '1',
      name: 'Homework',
      weight: 20,
      currentScore: 0,
      isCompleted: false,
    },
  ]);

  const addCategory = () => {
    const newId = (Math.max(...categories.map(c => parseInt(c.id)), 0) + 1).toString();
    setCategories([
      ...categories,
      {
        id: newId,
        name: '',
        weight: 0,
        currentScore: 0,
        isCompleted: false,
      },
    ]);
  };

  const removeCategory = (id: string) => {
    setCategories(categories.filter(c => c.id !== id));
  };

  const updateCategory = (id: string, field: keyof GradeCategory, value: any) => {
    setCategories(
      categories.map(c =>
        c.id === id ? { ...c, [field]: value } : c
      )
    );
  };

  const calculateResult = () => {
    const completedCategories = categories.filter(c => c.isCompleted);
    const remainingCategories = categories.filter(c => !c.isCompleted);

    // Calculate completed contribution
    const completedTotal = completedCategories.reduce(
      (sum, cat) => sum + (cat.currentScore * cat.weight) / 100,
      0
    );

    // Calculate remaining weight
    const remainingWeight = remainingCategories.reduce(
      (sum, cat) => sum + cat.weight,
      0
    );

    // Calculate total weight to check if it adds up to 100
    const totalWeight = categories.reduce((sum, cat) => sum + cat.weight, 0);

    if (remainingWeight === 0) {
      return {
        type: 'all-completed',
        message: `All components are completed. Your current course grade is ${completedTotal.toFixed(2)}%.`,
        currentGrade: completedTotal,
      };
    }

    // Calculate needed average on remaining
    const neededAverage = (targetGrade - completedTotal) / (remainingWeight / 100);

    if (neededAverage > 100) {
      return {
        type: 'impossible',
        message: `To hit ${targetGrade}%, you would need ${neededAverage.toFixed(2)}% on the remaining work, which isn't realistic.`,
        neededAverage,
      };
    }

    if (neededAverage < 0) {
      return {
        type: 'already-achieved',
        message: `You've already secured enough points to exceed your target (${targetGrade}%), even with 0% on the remaining work. Current grade: ${completedTotal.toFixed(2)}%.`,
        currentGrade: completedTotal,
      };
    }

    if (remainingCategories.length === 1) {
      return {
        type: 'single-remaining',
        message: `You need ${neededAverage.toFixed(2)}% on ${remainingCategories[0].name} to achieve ${targetGrade}%.`,
        neededAverage,
      };
    }

    return {
      type: 'multiple-remaining',
      message: `You need an average of ${neededAverage.toFixed(2)}% across all remaining categories to achieve ${targetGrade}%.`,
      neededAverage,
    };
  };

  const result = calculateResult();

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-8 shadow-sm space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold text-neutral-900 mb-2">
          Grade Planner
        </h2>
        <p className="text-neutral-600">
          Calculate what you need on remaining work to hit your target grade.
        </p>
      </div>

      {/* Course Name */}
      <div className="space-y-2">
        <label className="block text-sm font-semibold text-neutral-900">
          Course Name
        </label>
        <input
          type="text"
          value={courseName}
          onChange={(e) => setCourseName(e.target.value)}
          placeholder="e.g., MATH 2301 – Calculus I"
          className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
        />
      </div>

      {/* Target Grade */}
      <div className="space-y-2">
        <label className="block text-sm font-semibold text-neutral-900">
          Target Final Grade (%)
        </label>
        <input
          type="number"
          value={targetGrade}
          onChange={(e) => setTargetGrade(Number(e.target.value))}
          min="0"
          max="100"
          className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
        />
      </div>

      {/* Grade Breakdown Table */}
      <div className="space-y-3">
        <div className="flex items-center justify-between">
          <label className="block text-sm font-semibold text-neutral-900">
            Grade Breakdown
          </label>
          <button
            onClick={addCategory}
            className="px-3 py-1 bg-blue-500 text-white text-sm rounded-lg hover:bg-blue-600 transition-colors"
          >
            + Add Category
          </button>
        </div>

        {/* Table Header - Hidden on Mobile */}
        <div className="hidden md:grid md:grid-cols-12 gap-3 text-sm font-semibold text-neutral-700 pb-2 border-b border-neutral-200">
          <div className="col-span-4">Category Name</div>
          <div className="col-span-2">Weight (%)</div>
          <div className="col-span-2">Current Score (%)</div>
          <div className="col-span-2">Status</div>
          <div className="col-span-2"></div>
        </div>

        {/* Table Rows */}
        <div className="space-y-3">
          {categories.map((category) => (
            <div
              key={category.id}
              className="grid grid-cols-1 md:grid-cols-12 gap-3 items-start md:items-center p-3 md:p-0 bg-neutral-50 md:bg-transparent rounded-lg md:rounded-none border md:border-0 border-neutral-200"
            >
              {/* Category Name */}
              <div className="md:col-span-4">
                <label className="block md:hidden text-xs font-semibold text-neutral-600 mb-1">
                  Category
                </label>
                <input
                  type="text"
                  value={category.name}
                  onChange={(e) =>
                    updateCategory(category.id, 'name', e.target.value)
                  }
                  placeholder="e.g., Homework"
                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 text-sm"
                />
              </div>

              {/* Weight */}
              <div className="md:col-span-2">
                <label className="block md:hidden text-xs font-semibold text-neutral-600 mb-1">
                  Weight (%)
                </label>
                <input
                  type="number"
                  value={category.weight || ''}
                  onChange={(e) =>
                    updateCategory(category.id, 'weight', Number(e.target.value))
                  }
                  placeholder="20"
                  min="0"
                  max="100"
                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 text-sm"
                />
              </div>

              {/* Current Score */}
              <div className="md:col-span-2">
                <label className="block md:hidden text-xs font-semibold text-neutral-600 mb-1">
                  Current Score (%)
                </label>
                <input
                  type="number"
                  value={category.currentScore || ''}
                  onChange={(e) =>
                    updateCategory(
                      category.id,
                      'currentScore',
                      Number(e.target.value)
                    )
                  }
                  placeholder="85"
                  min="0"
                  max="100"
                  disabled={!category.isCompleted}
                  className="w-full px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 text-sm disabled:bg-neutral-100 disabled:text-neutral-400"
                />
              </div>

              {/* Status Toggle */}
              <div className="md:col-span-2">
                <label className="block md:hidden text-xs font-semibold text-neutral-600 mb-1">
                  Status
                </label>
                <button
                  onClick={() =>
                    updateCategory(
                      category.id,
                      'isCompleted',
                      !category.isCompleted
                    )
                  }
                  className={`w-full px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                    category.isCompleted
                      ? 'bg-green-100 text-green-800 border border-green-300'
                      : 'bg-neutral-100 text-neutral-600 border border-neutral-300'
                  }`}
                >
                  {category.isCompleted ? '✓ Completed' : '○ Remaining'}
                </button>
              </div>

              {/* Remove Button */}
              <div className="md:col-span-2 flex justify-end">
                <button
                  onClick={() => removeCategory(category.id)}
                  className="px-3 py-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors text-sm"
                  disabled={categories.length === 1}
                >
                  Remove
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Weight Total */}
        <div className="pt-2 border-t border-neutral-200">
          <p className="text-sm text-neutral-600">
            Total Weight:{' '}
            <span
              className={`font-semibold ${
                categories.reduce((sum, cat) => sum + cat.weight, 0) === 100
                  ? 'text-green-600'
                  : 'text-orange-600'
              }`}
            >
              {categories.reduce((sum, cat) => sum + cat.weight, 0)}%
            </span>
            {categories.reduce((sum, cat) => sum + cat.weight, 0) !== 100 && (
              <span className="text-orange-600 ml-2 text-xs">
                (Should sum to 100%)
              </span>
            )}
          </p>
        </div>
      </div>

      {/* Result Display */}
      <div
        className={`p-4 rounded-lg border-2 ${
          result.type === 'impossible'
            ? 'bg-red-50 border-red-300'
            : result.type === 'already-achieved'
            ? 'bg-green-50 border-green-300'
            : result.type === 'all-completed'
            ? 'bg-blue-50 border-blue-300'
            : 'bg-purple-50 border-purple-300'
        }`}
      >
        <p
          className={`font-semibold ${
            result.type === 'impossible'
              ? 'text-red-900'
              : result.type === 'already-achieved'
              ? 'text-green-900'
              : result.type === 'all-completed'
              ? 'text-blue-900'
              : 'text-purple-900'
          }`}
        >
          {result.message}
        </p>
      </div>
    </div>
  );
}
EOF

echo "✓ Created components/app/GradePlanner.tsx"

echo ""
echo "Updating /app page to include Grade Planner..."

cat << 'EOF' > app/app/page.tsx
'use client';

import React, { useState } from 'react';
import AppHeader from '@/components/app/AppHeader';
import Calendar from '@/components/app/Calendar';
import SyllabusUpload from '@/components/app/SyllabusUpload';
import EventsWidget from '@/components/app/EventsWidget';
import GradePlanner from '@/components/app/GradePlanner';

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
        <GradePlanner />
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
echo "  ✓ Created GradePlanner component"
echo "  ✓ Added Grade Planner to /app page"
echo ""
echo "Features:"
echo "  • Add/remove grade categories"
echo "  • Set weights and current scores"
echo "  • Mark categories as completed/remaining"
echo "  • Calculate needed grade for target"
echo "  • Responsive mobile layout"
echo ""
echo "To test:"
echo "  npm run dev"
echo "  Visit http://localhost:3000/app"
echo "  Scroll to Grade Planner section"
echo ""
