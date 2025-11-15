#!/usr/bin/env bash

echo "=========================================="
echo "Reorganizing /app with Tabs & Course Management"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Step 1: Creating types file..."
echo ""

cat << 'EOF' > types/app.ts
export interface Course {
  id: string;
  name: string;
  code: string;
  color: string;
  syllabusText: string;
  gradeCategories?: GradeCategory[];
}

export interface CalendarEvent {
  id: number;
  title: string;
  date: string;
  description?: string;
  courseId?: string;
}

export interface GradeCategory {
  id: string;
  name: string;
  weight: number;
  currentScore: number;
  isCompleted: boolean;
}
EOF

mkdir -p types
echo "✓ Created types/app.ts"

echo ""
echo "Step 2: Creating API route for grade parsing..."

cat << 'EOF' > app/api/parse-grades/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

interface GradeCategory {
  name: string;
  weight: number;
}

export async function POST(request: NextRequest) {
  try {
    const { syllabusText } = await request.json();

    if (!syllabusText || syllabusText.trim().length === 0) {
      return NextResponse.json({
        categories: [],
        error: 'No syllabus text provided'
      });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return NextResponse.json({
        categories: [],
        error: 'API key not configured'
      });
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `You are a syllabus grading breakdown parser. Extract the grading breakdown from the following course syllabus.

For each grading category (homework, quizzes, exams, projects, participation, etc.), extract:
- name: A clear, concise name for the category
- weight: The percentage weight (as a number, e.g., 20 for 20%)

Return ONLY a valid JSON array of categories. If no grading breakdown can be found, return an empty array [].

Example format:
[
  {
    "name": "Homework",
    "weight": 20
  },
  {
    "name": "Quizzes",
    "weight": 15
  },
  {
    "name": "Midterm Exam",
    "weight": 25
  },
  {
    "name": "Final Exam",
    "weight": 40
  }
]

IMPORTANT: 
- Only extract categories with clear percentage weights
- Weights should be numbers (not strings like "20%")
- The weights should ideally sum to 100, but extract what you find
- Do NOT include categories without weights
- Return ONLY the JSON array, no other text

Syllabus:
${syllabusText}`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    let categories: GradeCategory[] = [];
    try {
      const cleanedText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      categories = JSON.parse(cleanedText);
      
      if (!Array.isArray(categories)) {
        throw new Error('Response is not an array');
      }

      categories = categories.filter(cat => 
        cat.name && 
        typeof cat.weight === 'number' &&
        cat.weight > 0
      );
    } catch (parseError) {
      console.error('Failed to parse AI response:', text);
      return NextResponse.json({
        categories: [],
        error: 'Could not parse grade breakdown from this syllabus.'
      });
    }

    if (categories.length === 0) {
      return NextResponse.json({
        categories: [],
        error: 'No grading breakdown found in the syllabus.'
      });
    }

    return NextResponse.json({ categories });
  } catch (error) {
    console.error('Error parsing grades:', error);
    return NextResponse.json({
      categories: [],
      error: 'Could not parse grade breakdown from this syllabus.'
    });
  }
}
EOF

mkdir -p app/api/parse-grades
echo "✓ Created app/api/parse-grades/route.ts"

echo ""
echo "Step 3: Creating YourCourses component..."

cat << 'EOF' > components/app/YourCourses.tsx
'use client';

import React, { useState } from 'react';
import { Course } from '@/types/app';

interface YourCoursesProps {
  courses: Course[];
  onAddCourse: (course: Omit<Course, 'id'>) => Promise<void>;
  onEditCourse: (id: string, course: Omit<Course, 'id'>) => Promise<void>;
  onDeleteCourse: (id: string) => void;
  usedColors: string[];
}

const AVAILABLE_COLORS = [
  { name: 'Blue', value: '#3B82F6' },
  { name: 'Green', value: '#10B981' },
  { name: 'Purple', value: '#8B5CF6' },
  { name: 'Orange', value: '#F59E0B' },
  { name: 'Pink', value: '#EC4899' },
  { name: 'Teal', value: '#14B8A6' },
  { name: 'Red', value: '#EF4444' },
  { name: 'Indigo', value: '#6366F1' },
];

export default function YourCourses({
  courses,
  onAddCourse,
  onEditCourse,
  onDeleteCourse,
  usedColors,
}: YourCoursesProps) {
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    code: '',
    color: '',
    syllabusText: '',
    parseCalendar: true,
    parseGrades: true,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleOpenForm = (course?: Course) => {
    if (course) {
      setEditingId(course.id);
      setFormData({
        name: course.name,
        code: course.code,
        color: course.color,
        syllabusText: course.syllabusText,
        parseCalendar: false,
        parseGrades: false,
      });
    } else {
      setEditingId(null);
      setFormData({
        name: '',
        code: '',
        color: '',
        syllabusText: '',
        parseCalendar: true,
        parseGrades: true,
      });
    }
    setShowForm(true);
    setError('');
  };

  const handleCloseForm = () => {
    setShowForm(false);
    setEditingId(null);
    setError('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!formData.name.trim() || !formData.code.trim() || !formData.color) {
      setError('Please fill in course name, code, and select a color.');
      return;
    }

    if (!formData.syllabusText.trim()) {
      setError('Please paste syllabus text.');
      return;
    }

    if (editingId) {
      const existingCourse = courses.find(c => c.id === editingId);
      if (existingCourse && (formData.parseCalendar || formData.parseGrades)) {
        const shouldReparse = window.confirm(
          'Do you want to re-parse the syllabus? This will replace existing parsed data.'
        );
        if (!shouldReparse) {
          formData.parseCalendar = false;
          formData.parseGrades = false;
        }
      }
    }

    setIsSubmitting(true);

    try {
      const courseData = {
        name: formData.name,
        code: formData.code,
        color: formData.color,
        syllabusText: formData.syllabusText,
      };

      if (editingId) {
        await onEditCourse(editingId, courseData);
      } else {
        await onAddCourse(courseData);
      }

      handleCloseForm();
    } catch (err: any) {
      setError(err.message || 'Failed to save course');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = (id: string) => {
    const shouldDelete = window.confirm(
      'Delete this course? This will also remove all associated events from the calendar.'
    );
    if (shouldDelete) {
      onDeleteCourse(id);
    }
  };

  const availableColors = AVAILABLE_COLORS.filter(
    (c) => !usedColors.includes(c.value) || (editingId && formData.color === c.value)
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-neutral-900">Your Courses</h2>
          <p className="text-neutral-600 mt-1">
            Manage your courses and syllabi
          </p>
        </div>
        <button
          onClick={() => handleOpenForm()}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-colors"
        >
          + Add Course
        </button>
      </div>

      {/* Course List */}
      {courses.length === 0 ? (
        <div className="bg-white rounded-xl border border-neutral-200 p-12 text-center">
          <p className="text-neutral-600">
            No courses yet. Click "Add Course" to get started.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {courses.map((course) => (
            <div
              key={course.id}
              className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm hover:shadow-md transition-shadow"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div
                    className="w-4 h-4 rounded-full"
                    style={{ backgroundColor: course.color }}
                  ></div>
                  <div>
                    <h3 className="font-semibold text-neutral-900">
                      {course.name}
                    </h3>
                    <p className="text-sm text-neutral-600">{course.code}</p>
                  </div>
                </div>
              </div>
              
              {course.gradeCategories && course.gradeCategories.length > 0 && (
                <div className="mb-3 text-sm text-neutral-600">
                  <span className="font-medium">Grade categories:</span>{' '}
                  {course.gradeCategories.length} parsed
                </div>
              )}

              <div className="flex gap-2">
                <button
                  onClick={() => handleOpenForm(course)}
                  className="flex-1 px-3 py-2 bg-neutral-100 text-neutral-700 rounded-lg text-sm font-medium hover:bg-neutral-200 transition-colors"
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(course.id)}
                  className="flex-1 px-3 py-2 bg-red-50 text-red-600 rounded-lg text-sm font-medium hover:bg-red-100 transition-colors"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add/Edit Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-neutral-200 px-6 py-4">
              <div className="flex items-center justify-between">
                <h3 className="text-xl font-bold text-neutral-900">
                  {editingId ? 'Edit Course' : 'Add New Course'}
                </h3>
                <button
                  onClick={handleCloseForm}
                  className="text-neutral-400 hover:text-neutral-600"
                >
                  ✕
                </button>
              </div>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-6">
              {/* Course Name */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Course Name *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData({ ...formData, name: e.target.value })
                  }
                  placeholder="e.g., Calculus I"
                  className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
                  required
                />
              </div>

              {/* Course Code */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Course Code *
                </label>
                <input
                  type="text"
                  value={formData.code}
                  onChange={(e) =>
                    setFormData({ ...formData, code: e.target.value })
                  }
                  placeholder="e.g., MATH 2301"
                  className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
                  required
                />
              </div>

              {/* Color Picker */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Course Color *
                </label>
                <div className="grid grid-cols-4 gap-3">
                  {availableColors.map((color) => (
                    <button
                      key={color.value}
                      type="button"
                      onClick={() =>
                        setFormData({ ...formData, color: color.value })
                      }
                      className={`flex items-center gap-2 px-3 py-2 rounded-lg border-2 transition-all ${
                        formData.color === color.value
                          ? 'border-neutral-900 bg-neutral-50'
                          : 'border-neutral-200 hover:border-neutral-300'
                      }`}
                    >
                      <div
                        className="w-6 h-6 rounded-full"
                        style={{ backgroundColor: color.value }}
                      ></div>
                      <span className="text-sm">{color.name}</span>
                    </button>
                  ))}
                </div>
                {availableColors.length === 0 && (
                  <p className="text-sm text-orange-600">
                    All colors are in use. Delete a course to free up colors.
                  </p>
                )}
              </div>

              {/* Syllabus Text */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Syllabus Text *
                </label>
                <textarea
                  value={formData.syllabusText}
                  onChange={(e) =>
                    setFormData({ ...formData, syllabusText: e.target.value })
                  }
                  placeholder="Paste your course syllabus here..."
                  className="w-full h-48 px-4 py-3 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 resize-none"
                  required
                />
              </div>

              {/* Parsing Options */}
              {!editingId && (
                <div className="space-y-3 bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <p className="text-sm font-semibold text-blue-900">
                    AI Parsing Options
                  </p>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.parseCalendar}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          parseCalendar: e.target.checked,
                        })
                      }
                      className="w-4 h-4"
                    />
                    <span className="text-sm text-neutral-700">
                      Parse syllabus into calendar (deadlines)
                    </span>
                  </label>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.parseGrades}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          parseGrades: e.target.checked,
                        })
                      }
                      className="w-4 h-4"
                    />
                    <span className="text-sm text-neutral-700">
                      Parse syllabus into grade weights
                    </span>
                  </label>
                </div>
              )}

              {editingId && (
                <div className="space-y-3 bg-orange-50 border border-orange-200 rounded-lg p-4">
                  <p className="text-sm font-semibold text-orange-900">
                    Re-parse Syllabus
                  </p>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.parseCalendar}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          parseCalendar: e.target.checked,
                        })
                      }
                      className="w-4 h-4"
                    />
                    <span className="text-sm text-neutral-700">
                      Re-parse into calendar (replaces existing events)
                    </span>
                  </label>
                  <label className="flex items-center gap-3 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={formData.parseGrades}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          parseGrades: e.target.checked,
                        })
                      }
                      className="w-4 h-4"
                    />
                    <span className="text-sm text-neutral-700">
                      Re-parse grade weights (replaces existing breakdown)
                    </span>
                  </label>
                </div>
              )}

              {/* Error Message */}
              {error && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                  <p className="text-sm text-red-800">{error}</p>
                </div>
              )}

              {/* Submit Buttons */}
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={handleCloseForm}
                  className="flex-1 px-4 py-2 bg-neutral-100 text-neutral-700 rounded-lg font-medium hover:bg-neutral-200 transition-colors"
                  disabled={isSubmitting}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 disabled:bg-neutral-300 transition-colors"
                  disabled={isSubmitting}
                >
                  {isSubmitting
                    ? 'Saving...'
                    : editingId
                    ? 'Update Course'
                    : 'Add Course'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
EOF

echo "✓ Created components/app/YourCourses.tsx"

echo ""
echo "Step 4: Updating Calendar component..."

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
import { CalendarEvent, Course } from '@/types/app';

interface CalendarProps {
  events: CalendarEvent[];
  courses: Course[];
  onEditEvent: (event: CalendarEvent) => void;
  onDeleteEvent: (id: number) => void;
  onAddEvent: (date: string) => void;
  onRemoveAllEvents: () => void;
}

export default function Calendar({ 
  events, 
  courses,
  onEditEvent,
  onDeleteEvent,
  onAddEvent,
  onRemoveAllEvents
}: CalendarProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date(2025, 9, 1));
  const [selectedCourse, setSelectedCourse] = useState<string>('all');

  const nextMonth = () => {
    const next = addMonths(currentMonth, 1);
    if (next <= new Date(2026, 9, 31)) {
      setCurrentMonth(next);
    }
  };

  const prevMonth = () => {
    const prev = subMonths(currentMonth, 1);
    if (prev >= new Date(2025, 9, 1)) {
      setCurrentMonth(prev);
    }
  };

  const filteredEvents = selectedCourse === 'all' 
    ? events 
    : events.filter(e => e.courseId === selectedCourse);

  const handleRemoveAll = () => {
    const courseName = selectedCourse === 'all' 
      ? 'all courses' 
      : courses.find(c => c.id === selectedCourse)?.name || 'this course';
    
    const confirmed = window.confirm(
      `Remove all events for ${courseName}? This cannot be undone.`
    );
    
    if (confirmed) {
      onRemoveAllEvents();
    }
  };

  const renderHeader = () => {
    return (
      <div className="space-y-4 mb-6">
        <div className="flex items-center justify-between">
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

        {/* Filter and Actions */}
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <label className="text-sm font-medium text-neutral-700">
              Filter by course:
            </label>
            <select
              value={selectedCourse}
              onChange={(e) => setSelectedCourse(e.target.value)}
              className="px-3 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 text-sm"
            >
              <option value="all">All courses</option>
              {courses.map((course) => (
                <option key={course.id} value={course.id}>
                  {course.name}
                </option>
              ))}
            </select>
          </div>
          
          {filteredEvents.length > 0 && (
            <button
              onClick={handleRemoveAll}
              className="px-4 py-2 bg-red-50 text-red-600 border border-red-200 rounded-lg text-sm font-medium hover:bg-red-100 transition-colors"
            >
              Remove All Events
            </button>
          )}
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
        const dateString = format(day, 'yyyy-MM-dd');
        const dayEvents = filteredEvents.filter((event) =>
          isSameDay(parseISO(event.date), cloneDay)
        );

        days.push(
          <div
            key={day.toString()}
            onClick={() => {
              if (isSameMonth(day, monthStart)) {
                onAddEvent(dateString);
              }
            }}
            className={`min-h-[120px] p-2 border border-neutral-200 rounded-lg cursor-pointer transition-all ${
              !isSameMonth(day, monthStart)
                ? 'bg-neutral-50 text-neutral-400'
                : 'bg-white hover:bg-blue-50 hover:border-blue-300'
            }`}
          >
            <div className="font-semibold text-sm mb-1">{formattedDate}</div>
            <div className="space-y-1">
              {dayEvents.map((event) => {
                const course = courses.find(c => c.id === event.courseId);
                return (
                  <div
                    key={event.id}
                    onClick={(e) => {
                      e.stopPropagation();
                      onEditEvent(event);
                    }}
                    className="text-xs px-2 py-1 rounded truncate cursor-pointer hover:opacity-80"
                    style={{
                      backgroundColor: course?.color ? `${course.color}20` : '#DBEAFE',
                      borderLeft: `3px solid ${course?.color || '#3B82F6'}`
                    }}
                    title={event.title}
                  >
                    {event.title}
                  </div>
                );
              })}
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

  if (courses.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-neutral-200 p-12 text-center">
        <p className="text-neutral-600 text-lg">
          No courses yet. Add a course and syllabus from the "Your Courses" tab to see deadlines here.
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm">
      {renderHeader()}
      {renderDays()}
      {renderCells()}
    </div>
  );
}
EOF

echo "✓ Updated components/app/Calendar.tsx"

echo ""
echo "Step 5: Creating EventModal component..."

cat << 'EOF' > components/app/EventModal.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { CalendarEvent, Course } from '@/types/app';

interface EventModalProps {
  event: CalendarEvent | null;
  date?: string;
  courses: Course[];
  onSave: (event: CalendarEvent) => void;
  onDelete?: (id: number) => void;
  onClose: () => void;
}

export default function EventModal({
  event,
  date,
  courses,
  onSave,
  onDelete,
  onClose,
}: EventModalProps) {
  const [formData, setFormData] = useState({
    title: '',
    date: date || '',
    description: '',
    courseId: '',
  });

  useEffect(() => {
    if (event) {
      setFormData({
        title: event.title,
        date: event.date,
        description: event.description || '',
        courseId: event.courseId || '',
      });
    } else if (date) {
      setFormData({
        title: '',
        date,
        description: '',
        courseId: courses[0]?.id || '',
      });
    }
  }, [event, date, courses]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const eventData: CalendarEvent = {
      id: event?.id || Date.now(),
      title: formData.title,
      date: formData.date,
      description: formData.description,
      courseId: formData.courseId,
    };

    onSave(eventData);
    onClose();
  };

  const handleDelete = () => {
    if (event && onDelete) {
      const confirmed = window.confirm('Delete this event?');
      if (confirmed) {
        onDelete(event.id);
        onClose();
      }
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl max-w-lg w-full">
        <div className="border-b border-neutral-200 px-6 py-4">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-bold text-neutral-900">
              {event ? 'Edit Event' : 'New Event'}
            </h3>
            <button
              onClick={onClose}
              className="text-neutral-400 hover:text-neutral-600"
            >
              ✕
            </button>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-neutral-900">
              Title *
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) =>
                setFormData({ ...formData, title: e.target.value })
              }
              placeholder="e.g., Homework 1 Due"
              className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
              required
            />
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-neutral-900">
              Date *
            </label>
            <input
              type="date"
              value={formData.date}
              onChange={(e) =>
                setFormData({ ...formData, date: e.target.value })
              }
              className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
              required
            />
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-neutral-900">
              Course
            </label>
            <select
              value={formData.courseId}
              onChange={(e) =>
                setFormData({ ...formData, courseId: e.target.value })
              }
              className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
            >
              <option value="">No course</option>
              {courses.map((course) => (
                <option key={course.id} value={course.id}>
                  {course.name} ({course.code})
                </option>
              ))}
            </select>
          </div>

          <div className="space-y-2">
            <label className="block text-sm font-semibold text-neutral-900">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              placeholder="Optional details..."
              className="w-full h-24 px-4 py-3 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 resize-none"
            />
          </div>

          <div className="flex gap-3 pt-4">
            {event && onDelete && (
              <button
                type="button"
                onClick={handleDelete}
                className="px-4 py-2 bg-red-50 text-red-600 rounded-lg font-medium hover:bg-red-100 transition-colors"
              >
                Delete
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 bg-neutral-100 text-neutral-700 rounded-lg font-medium hover:bg-neutral-200 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-colors"
            >
              {event ? 'Update' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
EOF

echo "✓ Created components/app/EventModal.tsx"

echo ""
echo "Step 6: Updating GradePlanner component..."

cat << 'EOF' > components/app/GradePlanner.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { Course, GradeCategory } from '@/types/app';

interface GradePlannerProps {
  courses: Course[];
}

export default function GradePlanner({ courses }: GradePlannerProps) {
  const [selectedCourse, setSelectedCourse] = useState<string>('');
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

  useEffect(() => {
    if (selectedCourse) {
      const course = courses.find(c => c.id === selectedCourse);
      if (course?.gradeCategories && course.gradeCategories.length > 0) {
        setCategories(course.gradeCategories);
      } else {
        setCategories([
          {
            id: '1',
            name: 'Homework',
            weight: 20,
            currentScore: 0,
            isCompleted: false,
          },
        ]);
      }
    }
  }, [selectedCourse, courses]);

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

    const completedTotal = completedCategories.reduce(
      (sum, cat) => sum + (cat.currentScore * cat.weight) / 100,
      0
    );

    const remainingWeight = remainingCategories.reduce(
      (sum, cat) => sum + cat.weight,
      0
    );

    if (remainingWeight === 0) {
      return {
        type: 'all-completed',
        message: `All components are completed. Your current course grade is ${completedTotal.toFixed(2)}%.`,
        currentGrade: completedTotal,
      };
    }

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
  const selectedCourseData = courses.find(c => c.id === selectedCourse);
  const hasGradeParsing = selectedCourseData?.gradeCategories && selectedCourseData.gradeCategories.length > 0;

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-8 shadow-sm space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-neutral-900 mb-2">
          Grade Planner
        </h2>
        <p className="text-neutral-600">
          Calculate what you need on remaining work to hit your target grade.
        </p>
      </div>

      {courses.length === 0 ? (
        <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-8 text-center">
          <p className="text-neutral-600">
            Add a course from the "Your Courses" tab to use the grade planner.
          </p>
        </div>
      ) : (
        <>
          <div className="space-y-2">
            <label className="block text-sm font-semibold text-neutral-900">
              Select Course
            </label>
            <select
              value={selectedCourse}
              onChange={(e) => setSelectedCourse(e.target.value)}
              className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
            >
              <option value="">Choose a course...</option>
              {courses.map((course) => (
                <option key={course.id} value={course.id}>
                  {course.name} ({course.code})
                </option>
              ))}
            </select>
          </div>

          {selectedCourse && !hasGradeParsing && (
            <div className="bg-orange-50 border border-orange-200 rounded-lg p-3">
              <p className="text-sm text-orange-800">
                No grade breakdown was parsed from this syllabus. You can enter it manually below.
              </p>
            </div>
          )}

          {selectedCourse && (
            <>
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

                <div className="hidden md:grid md:grid-cols-12 gap-3 text-sm font-semibold text-neutral-700 pb-2 border-b border-neutral-200">
                  <div className="col-span-4">Category Name</div>
                  <div className="col-span-2">Weight (%)</div>
                  <div className="col-span-2">Current Score (%)</div>
                  <div className="col-span-2">Status</div>
                  <div className="col-span-2"></div>
                </div>

                <div className="space-y-3">
                  {categories.map((category) => (
                    <div
                      key={category.id}
                      className="grid grid-cols-1 md:grid-cols-12 gap-3 items-start md:items-center p-3 md:p-0 bg-neutral-50 md:bg-transparent rounded-lg md:rounded-none border md:border-0 border-neutral-200"
                    >
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

                      <div className="md:col-span-2">
                        <label className="block md:hidden text-xs font-semibold text-neutral-600 mb-1">
                          Status
                        </label>
                        <button
                          type="button"
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

                      <div className="md:col-span-2 flex justify-end">
                        <button
                          type="button"
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
            </>
          )}
        </>
      )}
    </div>
  );
}
EOF

echo "✓ Updated components/app/GradePlanner.tsx"

echo ""
echo "Step 7: Updating /app page with tabs..."

cat << 'EOF' > app/app/page.tsx
'use client';

import React, { useState } from 'react';
import AppHeader from '@/components/app/AppHeader';
import YourCourses from '@/components/app/YourCourses';
import Calendar from '@/components/app/Calendar';
import GradePlanner from '@/components/app/GradePlanner';
import EventModal from '@/components/app/EventModal';
import { Course, CalendarEvent, GradeCategory } from '@/types/app';

type Tab = 'courses' | 'calendar' | 'grades';

export default function AppPage() {
  const [activeTab, setActiveTab] = useState<Tab>('courses');
  const [courses, setCourses] = useState<Course[]>([]);
  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [eventModal, setEventModal] = useState<{
    event?: CalendarEvent;
    date?: string;
  } | null>(null);
  const [selectedCourse, setSelectedCourse] = useState<string>('all');

  const handleAddCourse = async (courseData: Omit<Course, 'id'>) => {
    const newCourse: Course = {
      id: Date.now().toString(),
      ...courseData,
    };

    // Parse calendar events if requested
    if ((courseData as any).parseCalendar) {
      try {
        const response = await fetch('/api/parse-syllabus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText: courseData.syllabusText }),
        });

        const data = await response.json();
        if (data.events && data.events.length > 0) {
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          const newEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description,
            courseId: newCourse.id,
          }));
          setEvents(prev => [...prev, ...newEvents]);
        }
      } catch (error) {
        console.error('Failed to parse calendar events:', error);
      }
    }

    // Parse grade categories if requested
    if ((courseData as any).parseGrades) {
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText: courseData.syllabusText }),
        });

        const data = await response.json();
        if (data.categories && data.categories.length > 0) {
          newCourse.gradeCategories = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
        }
      } catch (error) {
        console.error('Failed to parse grade categories:', error);
      }
    }

    setCourses(prev => [...prev, newCourse]);
  };

  const handleEditCourse = async (id: string, courseData: Omit<Course, 'id'>) => {
    const existingCourse = courses.find(c => c.id === id);
    if (!existingCourse) return;

    const updatedCourse: Course = {
      id,
      ...courseData,
      gradeCategories: existingCourse.gradeCategories,
    };

    // Re-parse calendar if requested
    if ((courseData as any).parseCalendar) {
      // Remove old events for this course
      setEvents(prev => prev.filter(e => e.courseId !== id));

      try {
        const response = await fetch('/api/parse-syllabus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText: courseData.syllabusText }),
        });

        const data = await response.json();
        if (data.events && data.events.length > 0) {
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          const newEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description,
            courseId: id,
          }));
          setEvents(prev => [...prev, ...newEvents]);
        }
      } catch (error) {
        console.error('Failed to parse calendar events:', error);
      }
    }

    // Re-parse grades if requested
    if ((courseData as any).parseGrades) {
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText: courseData.syllabusText }),
        });

        const data = await response.json();
        if (data.categories && data.categories.length > 0) {
          updatedCourse.gradeCategories = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
        }
      } catch (error) {
        console.error('Failed to parse grade categories:', error);
      }
    }

    setCourses(prev => prev.map(c => c.id === id ? updatedCourse : c));
  };

  const handleDeleteCourse = (id: string) => {
    setCourses(prev => prev.filter(c => c.id !== id));
    setEvents(prev => prev.filter(e => e.courseId !== id));
  };

  const handleSaveEvent = (event: CalendarEvent) => {
    if (events.find(e => e.id === event.id)) {
      setEvents(prev => prev.map(e => e.id === event.id ? event : e));
    } else {
      setEvents(prev => [...prev, event]);
    }
  };

  const handleDeleteEvent = (id: number) => {
    setEvents(prev => prev.filter(e => e.id !== id));
  };

  const handleRemoveAllEvents = () => {
    if (selectedCourse === 'all') {
      setEvents([]);
    } else {
      setEvents(prev => prev.filter(e => e.courseId !== selectedCourse));
    }
  };

  const usedColors = courses.map(c => c.color);

  return (
    <div className="min-h-screen bg-neutral-50">
      <AppHeader />

      {/* Tabs */}
      <div className="border-b border-neutral-200 bg-white">
        <div className="max-w-6xl mx-auto px-6">
          <div className="flex gap-8">
            <button
              onClick={() => setActiveTab('courses')}
              className={`py-4 px-2 font-medium text-sm border-b-2 transition-colors ${
                activeTab === 'courses'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900'
              }`}
            >
              Your Courses
            </button>
            <button
              onClick={() => setActiveTab('calendar')}
              className={`py-4 px-2 font-medium text-sm border-b-2 transition-colors ${
                activeTab === 'calendar'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900'
              }`}
            >
              Calendar
            </button>
            <button
              onClick={() => setActiveTab('grades')}
              className={`py-4 px-2 font-medium text-sm border-b-2 transition-colors ${
                activeTab === 'grades'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900'
              }`}
            >
              Grade Planner
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-6 py-8">
        {activeTab === 'courses' && (
          <YourCourses
            courses={courses}
            onAddCourse={handleAddCourse}
            onEditCourse={handleEditCourse}
            onDeleteCourse={handleDeleteCourse}
            usedColors={usedColors}
          />
        )}

        {activeTab === 'calendar' && (
          <Calendar
            events={events}
            courses={courses}
            onEditEvent={(event) => setEventModal({ event })}
            onDeleteEvent={handleDeleteEvent}
            onAddEvent={(date) => setEventModal({ date })}
            onRemoveAllEvents={handleRemoveAllEvents}
          />
        )}

        {activeTab === 'grades' && <GradePlanner courses={courses} />}
      </main>

      {/* Event Modal */}
      {eventModal && (
        <EventModal
          event={eventModal.event}
          date={eventModal.date}
          courses={courses}
          onSave={handleSaveEvent}
          onDelete={handleDeleteEvent}
          onClose={() => setEventModal(null)}
        />
      )}
    </div>
  );
}
EOF

echo "✓ Updated app/app/page.tsx"

echo ""
echo "Step 8: Removing old components..."

# Remove old components that are no longer used
rm -f components/app/SyllabusUpload.tsx 2>/dev/null || true
rm -f components/app/EventsWidget.tsx 2>/dev/null || true

echo "✓ Removed obsolete components"

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Created types/app.ts for TypeScript types"
echo "  ✓ Created /api/parse-grades route for grade parsing"
echo "  ✓ Created YourCourses component (course management hub)"
echo "  ✓ Updated Calendar component (with filtering & editing)"
echo "  ✓ Created EventModal component (add/edit/delete events)"
echo "  ✓ Updated GradePlanner component (course integration)"
echo "  ✓ Updated /app page with 3-tab navigation"
echo "  ✓ Removed old SyllabusUpload and EventsWidget components"
echo ""
echo "Features:"
echo "  • Tab navigation: Your Courses / Calendar / Grade Planner"
echo "  • Course management with color coding"
echo "  • AI parsing for calendar events AND grade weights"
echo "  • Calendar filtering by course"
echo "  • Click dates to add events, click events to edit"
echo "  • Grade planner auto-fills from parsed syllabus"
echo ""
echo "To test:"
echo "  npm run dev"
echo "  Visit http://localhost:3000/app"
echo "  Add a course with syllabus text"
echo "  Check both parsing options"
echo "  View results in Calendar and Grade Planner tabs"
echo ""
