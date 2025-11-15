'use client';

import React, { useState, useRef } from 'react';
import { Course } from '@/types/app';

interface YourCoursesProps {
  courses: Course[];
  onAddCourse: (course: Omit<Course, 'id'>, syllabusText: string, parseCalendar: boolean, lectureTimes?: string) => Promise<void>;
  onEditCourse: (id: string, course: Omit<Course, 'id'>, syllabusText: string, parseCalendar: boolean, lectureTimes?: string) => Promise<void>;
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
    lectureTimes: '',
    syllabusText: '',
    syllabusFile: null as File | null,
    parseCalendar: true,
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
        code: course.code || '',
        color: course.color,
        lectureTimes: course.lectureTimes || '',
        syllabusText: course.syllabusText || '',
        syllabusFile: null,
        parseCalendar: false,
      });
    } else {
      setEditingId(null);
      setFormData({
        name: '',
        code: '',
        color: '',
        lectureTimes: '',
        syllabusText: '',
        syllabusFile: null,
        parseCalendar: true,
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

  const handleFileSelect = async (file: File) => {
    if (!file) return;

    setFormData(prev => ({ ...prev, syllabusFile: file, syllabusText: '' }));

    // Only extract text from .txt files immediately (since it's instant)
    // PDF/DOCX extraction will happen when user submits with parsing options checked
    if (file.type === 'text/plain' || file.name.toLowerCase().endsWith('.txt')) {
      const text = await file.text();
      setFormData(prev => ({ ...prev, syllabusText: text }));
    }
  };

  const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      handleFileSelect(file);
    }
  };

  const handleDragOver = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDragLeave = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e: React.DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    e.stopPropagation();
    
    const file = e.dataTransfer.files?.[0];
    if (file) {
      // Validate file type
      const fileName = file.name.toLowerCase();
      if (fileName.endsWith('.pdf') || 
          fileName.endsWith('.docx') || 
          fileName.endsWith('.doc') || 
          fileName.endsWith('.txt')) {
        handleFileSelect(file);
      } else {
        setError('Unsupported file type. Please upload PDF, DOCX, DOC, or TXT files.');
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setParsingStatus('');

    if (!formData.name.trim() || !formData.color) {
      setError('Please fill in course name and select a color.');
      return;
    }

    if (editingId) {
      const existingCourse = courses.find(c => c.id === editingId);
      if (existingCourse && formData.parseCalendar) {
        const shouldReparse = window.confirm(
          'Do you want to re-parse the syllabus into calendar events? This will replace existing parsed events.'
        );
        if (!shouldReparse) {
          formData.parseCalendar = false;
        }
      }
    }

    setIsSubmitting(true);

    try {
      let syllabusText = formData.syllabusText;

      // If user wants to parse but there's a file with no text yet, extract text first
      if (formData.parseCalendar && 
          formData.syllabusFile && 
          !syllabusText.trim()) {
        const fileName = formData.syllabusFile.name.toLowerCase();
        
        if (fileName.endsWith('.txt')) {
          // Already handled in handleFileSelect for .txt files
          syllabusText = formData.syllabusText;
        } else if (fileName.endsWith('.pdf') || 
                   fileName.endsWith('.docx') || 
                   fileName.endsWith('.doc')) {
          // Extract text from PDF or DOCX using the API
          setParsingStatus('📄 Extracting text from file...');
          const uploadFormData = new FormData();
          uploadFormData.append('file', formData.syllabusFile);
          
          const response = await fetch('/api/extract-text', {
            method: 'POST',
            body: uploadFormData,
          });

          let data;
          try {
            data = await response.json();
          } catch (jsonError) {
            console.error('Failed to parse JSON response:', jsonError);
            const text = await response.text();
            console.error('Response text:', text);
            setError(`Failed to extract text: Server returned invalid response. Please try again.`);
            setIsSubmitting(false);
            setParsingStatus('');
            return;
          }
          
          if (!response.ok || data.error) {
            const errorMsg = data.error || `Server error (${response.status}). Please try again.`;
            console.error('[YourCourses] Extract text error:', errorMsg);
            setError(`Failed to extract text: ${errorMsg}`);
            setIsSubmitting(false);
            setParsingStatus('');
            return;
          } else if (data.text) {
            syllabusText = data.text;
            setFormData(prev => ({ ...prev, syllabusText: data.text }));
            setParsingStatus('');
          } else {
            setError('No text could be extracted from the file. The file may be empty or contain only images.');
            setIsSubmitting(false);
            setParsingStatus('');
            return;
          }
        }
      }

      const courseData = {
        name: formData.name,
        code: formData.code.trim() || undefined,
        color: formData.color,
        lectureTimes: formData.lectureTimes.trim() || undefined,
        syllabusText: syllabusText,
      };

      const hasSyllabus = syllabusText.trim().length > 0;
      const shouldParseCalendar = formData.parseCalendar && hasSyllabus;

      // Show parsing status
      if (shouldParseCalendar) {
        setParsingStatus('🔍 Analyzing syllabus...');
        await new Promise(resolve => setTimeout(resolve, 800));
      }

      if (editingId) {
        await onEditCourse(
          editingId, 
          courseData, 
          syllabusText,
          shouldParseCalendar,
          formData.lectureTimes.trim() || undefined
        );
      } else {
        await onAddCourse(
          courseData,
          syllabusText,
          shouldParseCalendar,
          formData.lectureTimes.trim() || undefined
        );
      }

      // Show completion status
      if (shouldParseCalendar) {
        setParsingStatus('✓ Calendar events imported');
        await new Promise(resolve => setTimeout(resolve, 1500));
      }
      
      if (formData.lectureTimes.trim()) {
        setParsingStatus('✓ Lecture events created');
        await new Promise(resolve => setTimeout(resolve, 1000));
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
                    {course.code && (
                      <p className="text-sm text-neutral-600">{course.code}</p>
                    )}
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
                  Course Code
                  <span className="text-xs font-normal text-neutral-500 ml-2">(Optional)</span>
                </label>
                <input
                  type="text"
                  value={formData.code}
                  onChange={(e) =>
                    setFormData({ ...formData, code: e.target.value })
                  }
                  placeholder="e.g., MATH 2301"
                  className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
                  disabled={isSubmitting}
                />
              </div>

              {/* Lecture Times */}
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-neutral-900">
                  Lecture Times
                  <span className="text-xs font-normal text-neutral-500 ml-2">(Optional)</span>
                </label>
                <input
                  type="text"
                  value={formData.lectureTimes}
                  onChange={(e) =>
                    setFormData({ ...formData, lectureTimes: e.target.value })
                  }
                  placeholder="e.g., Wednesday Fridays, 1:00 - 3:30 PM"
                  className="w-full px-4 py-2 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300"
                  disabled={isSubmitting}
                />
                <p className="text-xs text-neutral-500">
                  Format: Days (comma or space separated), Time Range (e.g., "Monday Wednesday, 9:00 AM - 10:30 AM")
                </p>
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
                  onDragOver={handleDragOver}
                  onDragLeave={handleDragLeave}
                  onDrop={handleDrop}
                  className="border-2 border-dashed border-neutral-300 rounded-lg p-6 text-center cursor-pointer hover:border-neutral-400 hover:bg-neutral-50 transition-colors"
                >
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept=".pdf,.doc,.docx,.txt"
                    onChange={handleFileInputChange}
                    className="hidden"
                    disabled={isSubmitting}
                  />
                  <div className="space-y-2">
                    <div className="text-3xl">📄</div>
                    <p className="text-sm text-neutral-700 font-medium">
                      {formData.syllabusFile
                        ? formData.syllabusFile.name
                        : 'Click to upload or drag and drop syllabus'}
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
              {(formData.syllabusText.trim().length > 0 || formData.syllabusFile) && (
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
