'use client';

import React, { useState, useEffect } from 'react';
import { format, parseISO } from 'date-fns';

interface CalendarEvent {
  id: number;
  title: string;
  date: string;
  description?: string;
  courseName?: string;
  color?: string;
}

interface EventDetailModalProps {
  event: CalendarEvent | null;
  isOpen: boolean;
  onClose: () => void;
  onEdit: (event: CalendarEvent) => void;
  onDelete: (eventId: number) => void;
}

export default function EventDetailModal({
  event,
  isOpen,
  onClose,
  onEdit,
  onDelete,
}: EventDetailModalProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editedTitle, setEditedTitle] = useState('');
  const [editedDate, setEditedDate] = useState('');
  const [editedDescription, setEditedDescription] = useState('');
  const [editedCourseName, setEditedCourseName] = useState('');

  useEffect(() => {
    if (event) {
      setEditedTitle(event.title);
      setEditedDate(event.date);
      setEditedDescription(event.description || '');
      setEditedCourseName(event.courseName || '');
      setIsEditing(false);
    }
  }, [event]);

  if (!isOpen || !event) return null;

  const handleSave = () => {
    if (editedTitle.trim() && editedDate.trim()) {
      onEdit({
        ...event,
        title: editedTitle.trim(),
        date: editedDate,
        description: editedDescription.trim() || undefined,
        courseName: editedCourseName.trim() || undefined,
      });
      setIsEditing(false);
      onClose();
    }
  };

  const handleDelete = () => {
    if (confirm('Are you sure you want to delete this event?')) {
      onDelete(event.id);
      onClose();
    }
  };

  const handleCancel = () => {
    if (event) {
      setEditedTitle(event.title);
      setEditedDate(event.date);
      setEditedDescription(event.description || '');
      setEditedCourseName(event.courseName || '');
    }
    setIsEditing(false);
  };

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-xl shadow-xl max-w-md w-full mx-4 p-6"
        onClick={(e) => e.stopPropagation()}
      >
        {!isEditing ? (
          <>
            <div className="flex items-start justify-between mb-4">
              <h2 className="text-2xl font-bold text-neutral-900">Event Details</h2>
              <button
                onClick={onClose}
                className="text-neutral-400 hover:text-neutral-600 transition-colors"
              >
                <svg
                  className="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="text-sm font-semibold text-neutral-600 block mb-1">
                  Title
                </label>
                <p className="text-neutral-900 text-lg">{event.title}</p>
              </div>

              <div>
                <label className="text-sm font-semibold text-neutral-600 block mb-1">
                  Date
                </label>
                <p className="text-neutral-900">
                  {format(parseISO(event.date), 'EEEE, MMMM d, yyyy')}
                </p>
              </div>

              {event.courseName && (
                <div>
                  <label className="text-sm font-semibold text-neutral-600 block mb-1">
                    Course
                  </label>
                  <p className="text-neutral-900">{event.courseName}</p>
                </div>
              )}

              {event.description && (
                <div>
                  <label className="text-sm font-semibold text-neutral-600 block mb-1">
                    Description
                  </label>
                  <p className="text-neutral-900 whitespace-pre-wrap">
                    {event.description}
                  </p>
                </div>
              )}

              <div className="flex gap-3 pt-4">
                <button
                  onClick={() => setIsEditing(true)}
                  className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
                >
                  Edit
                </button>
                <button
                  onClick={handleDelete}
                  className="flex-1 px-4 py-2 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 transition-colors"
                >
                  Delete
                </button>
              </div>
            </div>
          </>
        ) : (
          <>
            <div className="flex items-start justify-between mb-4">
              <h2 className="text-2xl font-bold text-neutral-900">Edit Event</h2>
              <button
                onClick={onClose}
                className="text-neutral-400 hover:text-neutral-600 transition-colors"
              >
                <svg
                  className="w-6 h-6"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="text-sm font-semibold text-neutral-600 block mb-1">
                  Title *
                </label>
                <input
                  type="text"
                  value={editedTitle}
                  onChange={(e) => setEditedTitle(e.target.value)}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Event title"
                />
              </div>

              <div>
                <label className="text-sm font-semibold text-neutral-600 block mb-1">
                  Date *
                </label>
                <input
                  type="date"
                  value={editedDate}
                  onChange={(e) => setEditedDate(e.target.value)}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="text-sm font-semibold text-neutral-600 block mb-1">
                  Course Name
                </label>
                <input
                  type="text"
                  value={editedCourseName}
                  onChange={(e) => setEditedCourseName(e.target.value)}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="e.g., CS 101, Math 200"
                />
                <p className="text-xs text-neutral-500 mt-1">
                  Changing the course name will update the event color
                </p>
              </div>

              <div>
                <label className="text-sm font-semibold text-neutral-600 block mb-1">
                  Description
                </label>
                <textarea
                  value={editedDescription}
                  onChange={(e) => setEditedDescription(e.target.value)}
                  className="w-full px-3 py-2 border border-neutral-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                  rows={4}
                  placeholder="Event description (optional)"
                />
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  onClick={handleCancel}
                  className="flex-1 px-4 py-2 bg-neutral-100 text-neutral-900 rounded-lg font-medium hover:bg-neutral-200 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSave}
                  disabled={!editedTitle.trim() || !editedDate.trim()}
                  className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Save
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

