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

interface CalendarEvent {
  id: number;
  title: string;
  date: string;
}

interface CalendarProps {
  events: CalendarEvent[];
}

export default function Calendar({ events }: CalendarProps) {
  const [currentMonth, setCurrentMonth] = useState(new Date(2025, 9, 1)); // October 2025

  const nextMonth = () => {
    const next = addMonths(currentMonth, 1);
    // Don't go past October 2026
    if (next <= new Date(2026, 9, 31)) {
      setCurrentMonth(next);
    }
  };

  const prevMonth = () => {
    const prev = subMonths(currentMonth, 1);
    // Don't go before October 2025
    if (prev >= new Date(2025, 9, 1)) {
      setCurrentMonth(prev);
    }
  };

  const renderHeader = () => {
    return (
      <div className="flex items-center justify-between mb-6">
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
        const dayEvents = events.filter((event) =>
          isSameDay(parseISO(event.date), cloneDay)
        );

        days.push(
          <div
            key={day.toString()}
            className={`min-h-[100px] p-2 border border-neutral-200 rounded-lg ${
              !isSameMonth(day, monthStart)
                ? 'bg-neutral-50 text-neutral-400'
                : 'bg-white hover:bg-neutral-50'
            } transition-colors`}
          >
            <div className="font-semibold text-sm mb-1">{formattedDate}</div>
            <div className="space-y-1">
              {dayEvents.map((event) => (
                <div
                  key={event.id}
                  className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded truncate"
                  title={event.title}
                >
                  {event.title}
                </div>
              ))}
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

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm">
      {renderHeader()}
      {renderDays()}
      {renderCells()}
    </div>
  );
}
