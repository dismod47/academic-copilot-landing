#!/usr/bin/env bash

echo "=========================================="
echo "Fixing Grade Breakdown Parsing"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Step 1: Checking and fixing parse-grades API route..."
echo ""

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

    console.log('[parse-grades] Received request with syllabus length:', syllabusText?.length);

    if (!syllabusText || syllabusText.trim().length === 0) {
      return NextResponse.json({
        categories: [],
        error: 'No syllabus text provided'
      });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error('[parse-grades] GEMINI_API_KEY not found in environment');
      return NextResponse.json({
        categories: [],
        error: 'API key not configured'
      });
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `You are a syllabus grading breakdown parser. Extract the grading breakdown from the following course syllabus.

For each grading category (homework, quizzes, exams, projects, participation, attendance, etc.), extract:
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
- Look for sections like "Grading", "Grade Breakdown", "Assessment", "Course Grades", "Evaluation"
- Only extract categories with clear percentage weights
- Weights should be numbers (not strings like "20%")
- The weights should ideally sum to 100, but extract what you find
- Do NOT include categories without weights
- Return ONLY the JSON array, no other text
- Do not wrap in markdown code blocks

Syllabus:
${syllabusText}`;

    console.log('[parse-grades] Calling Gemini API...');
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    console.log('[parse-grades] Gemini response:', text);

    let categories: GradeCategory[] = [];
    try {
      const cleanedText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      console.log('[parse-grades] Cleaned text:', cleanedText);
      
      categories = JSON.parse(cleanedText);
      console.log('[parse-grades] Parsed categories:', categories);
      
      if (!Array.isArray(categories)) {
        throw new Error('Response is not an array');
      }

      categories = categories.filter(cat => 
        cat.name && 
        typeof cat.weight === 'number' &&
        cat.weight > 0
      );
      
      console.log('[parse-grades] Filtered categories:', categories);
    } catch (parseError) {
      console.error('[parse-grades] Failed to parse AI response:', parseError);
      console.error('[parse-grades] Raw text:', text);
      return NextResponse.json({
        categories: [],
        error: 'Could not parse grade breakdown from this syllabus.'
      });
    }

    if (categories.length === 0) {
      console.log('[parse-grades] No categories found');
      return NextResponse.json({
        categories: [],
        error: 'No grading breakdown found in the syllabus.'
      });
    }

    console.log('[parse-grades] Success! Returning categories:', categories);
    return NextResponse.json({ categories });
  } catch (error) {
    console.error('[parse-grades] Error:', error);
    return NextResponse.json({
      categories: [],
      error: 'Could not parse grade breakdown from this syllabus.'
    });
  }
}
EOF

echo "✓ Updated app/api/parse-grades/route.ts with logging"

echo ""
echo "Step 2: Updating app/page.tsx to properly store grade categories..."

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

  const handleAddCourse = async (
    courseData: Omit<Course, 'id'>,
    syllabusText: string,
    parseCalendar: boolean,
    parseGrades: boolean
  ) => {
    console.log('[AppPage] Adding course:', { 
      courseName: courseData.name, 
      syllabusLength: syllabusText.length, 
      parseCalendar, 
      parseGrades 
    });

    const newCourse: Course = {
      id: Date.now().toString(),
      ...courseData,
      syllabusText: syllabusText,
    };

    let parsedEvents: CalendarEvent[] = [];
    let parsedGrades: GradeCategory[] = [];

    // Parse calendar events if requested
    if (parseCalendar && syllabusText.trim()) {
      console.log('[AppPage] Parsing calendar events...');
      try {
        const response = await fetch('/api/parse-syllabus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
        });

        const data = await response.json();
        console.log('[AppPage] Calendar parse response:', data);

        if (data.events && data.events.length > 0) {
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          parsedEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description || '',
            courseId: newCourse.id,
          }));
          console.log('[AppPage] Created calendar events:', parsedEvents);
        }
      } catch (error) {
        console.error('[AppPage] Failed to parse calendar events:', error);
      }
    }

    // Parse grade categories if requested
    if (parseGrades && syllabusText.trim()) {
      console.log('[AppPage] Parsing grade breakdown...');
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
        });

        const data = await response.json();
        console.log('[AppPage] Grade parse response:', data);

        if (data.categories && data.categories.length > 0) {
          parsedGrades = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
          console.log('[AppPage] Created grade categories:', parsedGrades);
          
          // CRITICAL: Store the parsed grades on the course object
          newCourse.gradeCategories = parsedGrades;
          console.log('[AppPage] Assigned gradeCategories to course:', newCourse.gradeCategories);
        } else {
          console.log('[AppPage] No grade categories in response');
        }
      } catch (error) {
        console.error('[AppPage] Failed to parse grade categories:', error);
      }
    }

    // Add course to state
    console.log('[AppPage] Final course object before adding to state:', newCourse);
    setCourses(prev => {
      const updated = [...prev, newCourse];
      console.log('[AppPage] Updated courses state:', updated);
      return updated;
    });

    // Add events to state
    if (parsedEvents.length > 0) {
      console.log('[AppPage] Adding events to state:', parsedEvents);
      setEvents(prev => {
        const updated = [...prev, ...parsedEvents];
        console.log('[AppPage] Updated events state:', updated);
        return updated;
      });
    }
  };

  const handleEditCourse = async (
    id: string,
    courseData: Omit<Course, 'id'>,
    syllabusText: string,
    parseCalendar: boolean,
    parseGrades: boolean
  ) => {
    const existingCourse = courses.find(c => c.id === id);
    if (!existingCourse) return;

    console.log('[AppPage] Editing course:', id, { parseCalendar, parseGrades });

    const updatedCourse: Course = {
      id,
      ...courseData,
      syllabusText: syllabusText,
      gradeCategories: existingCourse.gradeCategories,
    };

    // Re-parse calendar if requested
    if (parseCalendar && syllabusText.trim()) {
      console.log('[AppPage] Re-parsing calendar...');
      // Remove old events for this course
      setEvents(prev => prev.filter(e => e.courseId !== id));

      try {
        const response = await fetch('/api/parse-syllabus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
        });

        const data = await response.json();
        if (data.events && data.events.length > 0) {
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          const newEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description || '',
            courseId: id,
          }));
          setEvents(prev => [...prev, ...newEvents]);
        }
      } catch (error) {
        console.error('[AppPage] Failed to parse calendar events:', error);
      }
    }

    // Re-parse grades if requested
    if (parseGrades && syllabusText.trim()) {
      console.log('[AppPage] Re-parsing grades...');
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
        });

        const data = await response.json();
        console.log('[AppPage] Re-parse grade response:', data);
        
        if (data.categories && data.categories.length > 0) {
          updatedCourse.gradeCategories = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
          console.log('[AppPage] Updated gradeCategories:', updatedCourse.gradeCategories);
        }
      } catch (error) {
        console.error('[AppPage] Failed to parse grade categories:', error);
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

  // Debug logging
  console.log('[AppPage] Current state:', { 
    coursesCount: courses.length, 
    eventsCount: events.length,
    courses: courses.map(c => ({ 
      id: c.id, 
      name: c.name, 
      hasGrades: !!c.gradeCategories,
      gradeCount: c.gradeCategories?.length 
    }))
  });

  return (
    <div className="min-h-screen bg-neutral-50">
      <AppHeader />

      {/* Tabs */}
      <div className="border-b border-neutral-200 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex gap-8">
            <button
              onClick={() => setActiveTab('courses')}
              className={`py-4 px-2 font-medium text-sm border-b-2 transition-colors ${
                activeTab === 'courses'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900'
              }`}
            >
              Your Courses ({courses.length})
            </button>
            <button
              onClick={() => setActiveTab('calendar')}
              className={`py-4 px-2 font-medium text-sm border-b-2 transition-colors ${
                activeTab === 'calendar'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-neutral-600 hover:text-neutral-900'
              }`}
            >
              Calendar ({events.length} events)
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
      <main className={activeTab === 'calendar' ? 'w-full px-6 py-8' : 'max-w-6xl mx-auto px-6 py-8'}>
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
          <div className="max-w-7xl mx-auto">
            <Calendar
              events={events}
              courses={courses}
              selectedCourse={selectedCourse}
              onCourseFilterChange={setSelectedCourse}
              onEditEvent={(event) => setEventModal({ event })}
              onDeleteEvent={handleDeleteEvent}
              onAddEvent={(date) => setEventModal({ date })}
              onRemoveAllEvents={handleRemoveAllEvents}
            />
          </div>
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

echo "✓ Updated app/page.tsx with grade category storage"

echo ""
echo "Step 3: Updating GradePlanner to properly read gradeCategories..."

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
    console.log('[GradePlanner] Selected course changed:', selectedCourse);
    console.log('[GradePlanner] All courses:', courses);
    
    if (selectedCourse) {
      const course = courses.find(c => c.id === selectedCourse);
      console.log('[GradePlanner] Found course:', course);
      console.log('[GradePlanner] Grade categories:', course?.gradeCategories);
      
      if (course?.gradeCategories && course.gradeCategories.length > 0) {
        console.log('[GradePlanner] Setting categories from parsed data:', course.gradeCategories);
        setCategories(course.gradeCategories);
      } else {
        console.log('[GradePlanner] No grade categories, using default');
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

  console.log('[GradePlanner] Render state:', { 
    selectedCourse, 
    selectedCourseData, 
    hasGradeParsing,
    categories 
  });

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
                  {course.gradeCategories && course.gradeCategories.length > 0 
                    ? ` - ${course.gradeCategories.length} categories` 
                    : ''}
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

          {selectedCourse && hasGradeParsing && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-3">
              <p className="text-sm text-green-800">
                ✓ Grade breakdown loaded from syllabus ({selectedCourseData.gradeCategories?.length} categories)
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

echo "✓ Updated components/app/GradePlanner.tsx with debugging"

echo ""
echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Added extensive logging to parse-grades API"
echo "  ✓ Fixed grade category storage in course object"
echo "  ✓ Added debugging to GradePlanner component"
echo "  ✓ Added success message when grades are loaded"
echo "  ✓ Added category count to course selector"
echo ""
echo "To test:"
echo "  1. npm run dev"
echo "  2. Open browser console (F12)"
echo "  3. Add a course with syllabus"
echo "  4. Check 'Parse syllabus into grade weights'"
echo "  5. Watch console logs"
echo "  6. Go to Grade Planner tab"
echo "  7. Select the course"
echo "  8. Should see parsed categories!"
echo ""
