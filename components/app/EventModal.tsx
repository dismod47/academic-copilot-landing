'use client';

import React, { useState, useEffect } from 'react';
import { CalendarEvent, Course } from '@/types/app';

interface EventModalProps {
  event: CalendarEvent | null;
  date?: string;
  courses: Course[];
  onSave: (event: CalendarEvent) => void;
  onDelete?: (id: string) => void;
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
      id: event?.id || `temp-${Date.now()}`,
      title: formData.title,
      date: formData.date,
      description: formData.description,
      courseId: formData.courseId || undefined, // Convert empty string to undefined
      type: 'other',
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
              <option value="">Other</option>
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
