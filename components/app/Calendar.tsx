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
  onDeleteEvent: (id: string) => void;
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
  // Set initial month to current month, but default to January 2024 if current is before that
  const getInitialMonth = () => {
    const now = new Date();
    const minDate = new Date(2024, 0, 1); // January 1, 2024
    const maxDate = new Date(2027, 11, 31); // December 31, 2027
    
    if (now < minDate) return minDate;
    if (now > maxDate) return maxDate;
    return now;
  };

  const [currentMonth, setCurrentMonth] = useState(getInitialMonth());

  const minDate = new Date(2024, 0, 1); // January 1, 2024
  const maxDate = new Date(2027, 11, 31); // December 31, 2027

  const nextMonth = () => {
    const next = addMonths(currentMonth, 1);
    // Check if the next month's start is before or equal to maxDate
    const nextMonthStart = startOfMonth(next);
    const maxDateStart = startOfMonth(maxDate);
    if (nextMonthStart <= maxDateStart) {
      setCurrentMonth(next);
    }
  };

  const prevMonth = () => {
    const prev = subMonths(currentMonth, 1);
    // Check if the previous month's start is after or equal to minDate
    const prevMonthStart = startOfMonth(prev);
    const minDateStart = startOfMonth(minDate);
    if (prevMonthStart >= minDateStart) {
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
              disabled={startOfMonth(currentMonth) <= startOfMonth(minDate)}
              className="px-4 py-2 bg-neutral-100 border border-neutral-200 rounded-lg text-neutral-900 text-sm font-medium hover:bg-neutral-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Previous
            </button>
            <button
              onClick={nextMonth}
              disabled={startOfMonth(currentMonth) >= startOfMonth(maxDate)}
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

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm w-full">
      {renderHeader()}
      {renderDays()}
      {renderCells()}
    </div>
  );
}
