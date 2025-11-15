#!/usr/bin/env bash

echo "=========================================="
echo "EMERGENCY FIX: Calendar Parsing"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Fixing YourCourses component with proper parsing flow..."
echo ""

cat << 'EOF' > components/app/YourCourses.tsx
'use client';

import React, { useState, useRef } from 'react';
import { Course } from '@/types/app';

interface YourCoursesProps {
  courses: Course[];
  onAddCourse: (course: Omit<Course, 'id'>, syllabusText: string, parseCalendar: boolean, parseGrades: boolean) => Promise<void>;
  onEditCourse: (id: string, course: Omit<Course, 'id'>, syllabusText: string, parseCalendar: boolean, parseGrades: boolean) => Promise<void>;
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
    syllabusFile: null as File | null,
    parseCalendar: true,
    parseGrades: true,
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [parsingStatus, setParsingStatus] = useState('');
  const [error, setError] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleOpenForm = (course?: Course) => {
    if (course) {
      setEditingId(course.id);
      setFormData({
        name: course.name,
        code: course.code,
        color: course.color,
        syllabusText: course.syllabusText,
        syllabusFile: null,
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
        syllabusFile: null,
        parseCalendar: true,
        parseGrades: true,
      });
    }
    setShowForm(true);
    setError('');
    setParsingStatus('');
  };

  const handleCloseForm = () => {
    setShowForm(false);
    setEditingId(null);
    setError('');
    setParsingStatus('');
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setFormData({ ...formData, syllabusFile: file });

    // Try to extract text from file
    if (file.type === 'text/plain') {
      const text = await file.text();
      setFormData(prev => ({ ...prev, syllabusText: text }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setParsingStatus('');

    if (!formData.name.trim() || !formData.code.trim() || !formData.color) {
      setError('Please fill in course name, code, and select a color.');
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

      const hasSyllabus = formData.syllabusText.trim().length > 0;
      const shouldParseCalendar = formData.parseCalendar && hasSyllabus;
      const shouldParseGrades = formData.parseGrades && hasSyllabus;

      // Show parsing status
      if (shouldParseCalendar || shouldParseGrades) {
        setParsingStatus('🔍 Analyzing syllabus...');
        await new Promise(resolve => setTimeout(resolve, 800));
      }

      if (editingId) {
        await onEditCourse(
          editingId, 
          courseData, 
          formData.syllabusText,
          shouldParseCalendar,
          shouldParseGrades
        );
      } else {
        await onAddCourse(
          courseData,
          formData.syllabusText,
          shouldParseCalendar,
          shouldParseGrades
        );
      }

      // Show completion status
      if (shouldParseCalendar || shouldParseGrades) {
        const messages = [];
        if (shouldParseCalendar) messages.push('✓ Calendar events imported');
        if (shouldParseGrades) messages.push('✓ Grade breakdown imported');
        
        setParsingStatus(messages.join('\n'));
        await new Promise(resolve => setTimeout(resolve, 1500));
      }

      handleCloseForm();
    } catch (err: any) {
      setError(err.message || 'Failed to save course');
      setParsingStatus('');
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
            <div className="sticky top-0 bg-white border-b border-neutral-200 px-6 py-4 z-10">
              <div className="flex items-center justify-between">
                <h3 className="text-xl font-bold text-neutral-900">
                  {editingId ? 'Edit Course' : 'Add New Course'}
                </h3>
                <button
                  onClick={handleCloseForm}
                  className="text-neutral-400 hover:text-neutral-600"
                  disabled={isSubmitting}
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
                  disabled={isSubmitting}
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
                  disabled={isSubmitting}
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
                      disabled={isSubmitting}
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

              {/* File Upload */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Upload Syllabus (Optional)
                </label>
                <div
                  onClick={() => fileInputRef.current?.click()}
                  className="border-2 border-dashed border-neutral-300 rounded-lg p-6 text-center cursor-pointer hover:border-neutral-400 hover:bg-neutral-50 transition-colors"
                >
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept=".pdf,.doc,.docx,.txt"
                    onChange={handleFileSelect}
                    className="hidden"
                    disabled={isSubmitting}
                  />
                  <div className="space-y-2">
                    <div className="text-3xl">📄</div>
                    <p className="text-sm text-neutral-700 font-medium">
                      {formData.syllabusFile
                        ? formData.syllabusFile.name
                        : 'Click to upload syllabus'}
                    </p>
                    <p className="text-xs text-neutral-500">
                      Supports PDF, DOC, DOCX, TXT
                    </p>
                  </div>
                </div>
              </div>

              {/* Syllabus Text */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Or Paste Syllabus Text (Optional)
                </label>
                <textarea
                  value={formData.syllabusText}
                  onChange={(e) =>
                    setFormData({ ...formData, syllabusText: e.target.value })
                  }
                  placeholder="Paste your course syllabus here..."
                  className="w-full h-48 px-4 py-3 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 resize-none"
                  disabled={isSubmitting}
                />
                {formData.syllabusText.trim().length > 0 && (
                  <p className="text-xs text-neutral-500">
                    {formData.syllabusText.length} characters
                  </p>
                )}
              </div>

              {/* Parsing Options */}
              {formData.syllabusText.trim().length > 0 && (
                <>
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
                          disabled={isSubmitting}
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
                          disabled={isSubmitting}
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
                          disabled={isSubmitting}
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
                          disabled={isSubmitting}
                        />
                        <span className="text-sm text-neutral-700">
                          Re-parse grade weights (replaces existing breakdown)
                        </span>
                      </label>
                    </div>
                  )}
                </>
              )}

              {/* Parsing Status */}
              {parsingStatus && (
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <div className="flex items-center gap-3">
                    {!parsingStatus.includes('✓') && (
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
                    )}
                    <p className="text-sm text-blue-900 whitespace-pre-line">
                      {parsingStatus}
                    </p>
                  </div>
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

echo "✓ Updated YourCourses component"

echo ""
echo "Fixing app/page.tsx with explicit parsing logic..."

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
    console.log('Adding course:', { courseData, syllabusText: syllabusText.substring(0, 100), parseCalendar, parseGrades });

    const newCourse: Course = {
      id: Date.now().toString(),
      ...courseData,
      syllabusText: syllabusText,
    };

    let parsedEvents: CalendarEvent[] = [];
    let parsedGrades: GradeCategory[] = [];

    // Parse calendar events if requested
    if (parseCalendar && syllabusText.trim()) {
      console.log('Calling parse-syllabus API...');
      try {
        const response = await fetch('/api/parse-syllabus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
        });

        const data = await response.json();
        console.log('Parse-syllabus response:', data);

        if (data.events && data.events.length > 0) {
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          parsedEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description || '',
            courseId: newCourse.id,
          }));
          console.log('Parsed events:', parsedEvents);
        } else {
          console.log('No events found in response');
        }
      } catch (error) {
        console.error('Failed to parse calendar events:', error);
      }
    }

    // Parse grade categories if requested
    if (parseGrades && syllabusText.trim()) {
      console.log('Calling parse-grades API...');
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
        });

        const data = await response.json();
        console.log('Parse-grades response:', data);

        if (data.categories && data.categories.length > 0) {
          parsedGrades = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
          console.log('Parsed grades:', parsedGrades);
        } else {
          console.log('No grade categories found in response');
        }
      } catch (error) {
        console.error('Failed to parse grade categories:', error);
      }
    }

    // Update course with parsed data
    if (parsedGrades.length > 0) {
      newCourse.gradeCategories = parsedGrades;
    }

    // Add course to state
    console.log('Adding course to state:', newCourse);
    setCourses(prev => {
      const updated = [...prev, newCourse];
      console.log('Updated courses:', updated);
      return updated;
    });

    // Add events to state
    if (parsedEvents.length > 0) {
      console.log('Adding events to state:', parsedEvents);
      setEvents(prev => {
        const updated = [...prev, ...parsedEvents];
        console.log('Updated events:', updated);
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

    const updatedCourse: Course = {
      id,
      ...courseData,
      syllabusText: syllabusText,
      gradeCategories: existingCourse.gradeCategories,
    };

    // Re-parse calendar if requested
    if (parseCalendar && syllabusText.trim()) {
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
        console.error('Failed to parse calendar events:', error);
      }
    }

    // Re-parse grades if requested
    if (parseGrades && syllabusText.trim()) {
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText }),
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

  // Debug logging
  console.log('Current state:', { courses, events, selectedCourse });

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

echo "✓ Updated app/page.tsx with debug logging"

echo ""
echo "=========================================="
echo "EMERGENCY FIX COMPLETE!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Fixed parameter passing from YourCourses to parent"
echo "  ✓ Added explicit syllabusText parameter"
echo "  ✓ Fixed parsing flags being passed correctly"
echo "  ✓ Added extensive console.log debugging"
echo "  ✓ Fixed state updates for both courses and events"
echo "  ✓ Added event counter in Calendar tab"
echo ""
echo "To test:"
echo "  npm run dev"
echo "  Open browser console (F12)"
echo "  Add a course with syllabus text"
echo "  Check console for parsing logs"
echo "  Go to Calendar tab - should show events"
echo ""
echo "If still not working, check console for errors!"
echo ""
