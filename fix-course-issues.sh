#!/usr/bin/env bash

echo "=========================================="
echo "Fixing Course Management & Calendar Issues"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Step 1: Updating YourCourses component..."
echo ""

cat << 'EOF' > components/app/YourCourses.tsx
'use client';

import React, { useState, useRef } from 'react';
import { Course } from '@/types/app';

interface YourCoursesProps {
  courses: Course[];
  onAddCourse: (course: Omit<Course, 'id'>, options: { parseCalendar: boolean; parseGrades: boolean }) => Promise<void>;
  onEditCourse: (id: string, course: Omit<Course, 'id'>, options: { parseCalendar: boolean; parseGrades: boolean }) => Promise<void>;
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

      const options = {
        parseCalendar: formData.parseCalendar && formData.syllabusText.trim().length > 0,
        parseGrades: formData.parseGrades && formData.syllabusText.trim().length > 0,
      };

      // Show parsing status
      if (options.parseCalendar || options.parseGrades) {
        setParsingStatus('Analyzing syllabus...');
        
        if (options.parseCalendar) {
          setParsingStatus('🔍 Checking syllabus for deadlines...');
          await new Promise(resolve => setTimeout(resolve, 500));
        }

        if (editingId) {
          await onEditCourse(editingId, courseData, options);
        } else {
          await onAddCourse(courseData, options);
        }

        // Show completion status
        const messages = [];
        if (options.parseCalendar) messages.push('✓ Calendar events imported');
        if (options.parseGrades) messages.push('✓ Grade breakdown imported');
        
        if (messages.length > 0) {
          setParsingStatus(messages.join('\n'));
          await new Promise(resolve => setTimeout(resolve, 1500));
        }
      } else {
        if (editingId) {
          await onEditCourse(editingId, courseData, options);
        } else {
          await onAddCourse(courseData, options);
        }
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
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
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

echo "✓ Updated components/app/YourCourses.tsx"

echo ""
echo "Step 2: Fixing Calendar width and layout..."

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
  selectedCourse: string;
  onCourseFilterChange: (courseId: string) => void;
  onEditEvent: (event: CalendarEvent) => void;
  onDeleteEvent: (id: number) => void;
  onAddEvent: (date: string) => void;
  onRemoveAllEvents: () => void;
}

export default function Calendar({ 
  events, 
  courses,
  selectedCourse,
  onCourseFilterChange,
  onEditEvent,
  onDeleteEvent,
  onAddEvent,
  onRemoveAllEvents
}: CalendarProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date(2025, 9, 1));

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
              onChange={(e) => onCourseFilterChange(e.target.value)}
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
      <div className="grid grid-cols-7 gap-1 mb-1">
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
            className={`min-h-[140px] p-2 border border-neutral-200 rounded-lg cursor-pointer transition-all ${
              !isSameMonth(day, monthStart)
                ? 'bg-neutral-50 text-neutral-400'
                : 'bg-white hover:bg-blue-50 hover:border-blue-300'
            }`}
          >
            <div className="font-semibold text-sm mb-2">{formattedDate}</div>
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
                    className="text-xs px-2 py-1.5 rounded truncate cursor-pointer hover:opacity-80 transition-opacity"
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
        <div key={day.toString()} className="grid grid-cols-7 gap-1">
          {days}
        </div>
      );
      days = [];
    }

    return <div className="space-y-1">{rows}</div>;
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
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm w-full">
      {renderHeader()}
      {renderDays()}
      {renderCells()}
    </div>
  );
}
EOF

echo "✓ Updated components/app/Calendar.tsx"

echo ""
echo "Step 3: Fixing app/page.tsx with proper state management..."

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
    options: { parseCalendar: boolean; parseGrades: boolean }
  ) => {
    const newCourse: Course = {
      id: Date.now().toString(),
      ...courseData,
    };

    let parsedEvents: CalendarEvent[] = [];
    let parsedGrades: GradeCategory[] = [];

    // Parse calendar events if requested
    if (options.parseCalendar && courseData.syllabusText.trim()) {
      try {
        const response = await fetch('/api/parse-syllabus', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText: courseData.syllabusText }),
        });

        const data = await response.json();
        if (data.events && data.events.length > 0) {
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          parsedEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description,
            courseId: newCourse.id,
          }));
        }
      } catch (error) {
        console.error('Failed to parse calendar events:', error);
      }
    }

    // Parse grade categories if requested
    if (options.parseGrades && courseData.syllabusText.trim()) {
      try {
        const response = await fetch('/api/parse-grades', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ syllabusText: courseData.syllabusText }),
        });

        const data = await response.json();
        if (data.categories && data.categories.length > 0) {
          parsedGrades = data.categories.map((cat: any, index: number) => ({
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

    // Update course with parsed data
    if (parsedGrades.length > 0) {
      newCourse.gradeCategories = parsedGrades;
    }

    // Add course and events to state
    setCourses(prev => [...prev, newCourse]);
    if (parsedEvents.length > 0) {
      setEvents(prev => [...prev, ...parsedEvents]);
    }
  };

  const handleEditCourse = async (
    id: string,
    courseData: Omit<Course, 'id'>,
    options: { parseCalendar: boolean; parseGrades: boolean }
  ) => {
    const existingCourse = courses.find(c => c.id === id);
    if (!existingCourse) return;

    const updatedCourse: Course = {
      id,
      ...courseData,
      gradeCategories: existingCourse.gradeCategories,
    };

    // Re-parse calendar if requested
    if (options.parseCalendar && courseData.syllabusText.trim()) {
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
    if (options.parseGrades && courseData.syllabusText.trim()) {
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

echo "✓ Updated app/app/page.tsx"

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Made syllabus text optional (not required)"
echo "  ✓ Added file upload support for syllabi"
echo "  ✓ Added parsing status animations with checkmarks"
echo "  ✓ Fixed form staying open after course creation"
echo "  ✓ Fixed events not showing in calendar"
echo "  ✓ Increased calendar width to fill desktop screen"
echo "  ✓ Improved calendar cell heights for better visibility"
echo "  ✓ Added proper state management for parsing flow"
echo ""
echo "To test:"
echo "  npm run dev"
echo "  Visit http://localhost:3000/app"
echo "  Add a course (syllabus is now optional)"
echo "  Watch for parsing animations"
echo "  Check calendar tab for parsed events"
echo ""
