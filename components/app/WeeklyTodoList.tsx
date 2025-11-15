'use client';

import React, { useMemo } from 'react';
import { 
  startOfWeek, 
  endOfWeek, 
  format, 
  parseISO,
  isWithinInterval,
  isBefore,
  addDays
} from 'date-fns';
import { CalendarEvent, Course } from '@/types/app';

interface WeeklyTodoListProps {
  events: CalendarEvent[];
  courses: Course[];
}

interface TodoItem {
  id: string;
  title: string;
  date: Date;
  type: string;
  priority: number;
  courseName?: string;
  color?: string;
}

export default function WeeklyTodoList({ events, courses }: WeeklyTodoListProps) {
  const today = new Date();
  const weekStart = startOfWeek(today, { weekStartsOn: 0 }); // Sunday
  const weekEnd = endOfWeek(today, { weekStartsOn: 0 }); // Saturday

  // Get events for this week
  const weeklyEvents = useMemo(() => {
    return events.filter(event => {
      const eventDate = parseISO(event.date);
      return isWithinInterval(eventDate, { start: weekStart, end: weekEnd });
    });
  }, [events, weekStart, weekEnd]);

  // Get priority based on event type
  const getPriority = (type?: string): number => {
    if (!type) return 5;
    
    const typeLower = type.toLowerCase();
    if (typeLower.includes('exam') || typeLower.includes('test') || typeLower.includes('final')) {
      return 1; // Highest priority
    }
    if (typeLower.includes('quiz') || typeLower.includes('midterm')) {
      return 2;
    }
    if (typeLower.includes('project') || typeLower.includes('assignment')) {
      return 3;
    }
    if (typeLower.includes('homework') || typeLower.includes('hw')) {
      return 4;
    }
    if (typeLower.includes('reading') || typeLower.includes('reading')) {
      return 6;
    }
    return 5; // Default/Other
  };

  // Create todo items from events
  const todoItems = useMemo(() => {
    const items: TodoItem[] = [];

    // Add regular event items
    weeklyEvents.forEach(event => {
      const eventDate = parseISO(event.date);
      const course = event.courseId ? courses.find(c => c.id === event.courseId) : null;

      items.push({
        id: event.id,
        title: event.title,
        date: eventDate,
        type: event.type || 'other',
        priority: getPriority(event.type),
        courseName: course?.name,
        color: course?.color,
      });

      // If it's an exam/test, add a "Study for" task
      const typeLower = (event.type || '').toLowerCase();
      if (typeLower.includes('exam') || typeLower.includes('test') || typeLower.includes('final') || typeLower.includes('midterm')) {
        // Add study task 2-3 days before the exam
        const studyDate = addDays(eventDate, -2);
        
        // Only add study task if it's still in the future (not in the past)
        if (isBefore(today, studyDate) || isWithinInterval(studyDate, { start: weekStart, end: weekEnd })) {
          items.push({
            id: `${event.id}-study`,
            title: `Study for ${event.title}`,
            date: studyDate,
            type: 'study',
            priority: 1, // Same priority as exam
            courseName: course?.name,
            color: course?.color,
          });
        }
      }
    });

    // Sort by priority (lower number = higher priority), then by date
    return items.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority - b.priority;
      }
      return a.date.getTime() - b.date.getTime();
    });
  }, [weeklyEvents, courses, weekStart, weekEnd, today]);

  const getPriorityLabel = (priority: number): string => {
    if (priority === 1) return 'High';
    if (priority <= 2) return 'Medium-High';
    if (priority <= 3) return 'Medium';
    return 'Low';
  };

  const getPriorityColor = (priority: number): string => {
    if (priority === 1) return 'bg-red-100 text-red-700 border-red-300';
    if (priority <= 2) return 'bg-orange-100 text-orange-700 border-orange-300';
    if (priority <= 3) return 'bg-yellow-100 text-yellow-700 border-yellow-300';
    return 'bg-blue-100 text-blue-700 border-blue-300';
  };

  const getTypeIcon = (type: string): string => {
    const typeLower = type.toLowerCase();
    if (typeLower.includes('exam') || typeLower.includes('test') || typeLower.includes('final')) {
      return '📝';
    }
    if (typeLower.includes('quiz')) {
      return '✏️';
    }
    if (typeLower.includes('project')) {
      return '📋';
    }
    if (typeLower.includes('homework') || typeLower.includes('hw') || typeLower.includes('assignment')) {
      return '📄';
    }
    if (typeLower.includes('reading')) {
      return '📖';
    }
    if (typeLower === 'study') {
      return '📚';
    }
    return '📌';
  };

  if (todoItems.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm mt-6">
        <h3 className="text-xl font-semibold text-neutral-900 mb-4">
          Weekly To-Do List
        </h3>
        <p className="text-neutral-600 text-center py-8">
          No items for this week. You're all caught up! 🎉
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm mt-6">
      <h3 className="text-xl font-semibold text-neutral-900 mb-4">
        Weekly To-Do List
        <span className="text-sm font-normal text-neutral-500 ml-2">
          ({format(weekStart, 'MMM d')} - {format(weekEnd, 'MMM d, yyyy')})
        </span>
      </h3>

      <div className="space-y-3">
        {todoItems.map((item) => {
          const isPast = isBefore(item.date, today) && !isWithinInterval(item.date, { start: weekStart, end: weekEnd });
          
          return (
            <div
              key={item.id}
              className={`flex items-start gap-4 p-4 rounded-lg border-2 transition-all ${
                isPast
                  ? 'bg-neutral-50 border-neutral-200 opacity-60'
                  : getPriorityColor(item.priority)
              }`}
            >
              <div className="text-2xl flex-shrink-0">
                {getTypeIcon(item.type)}
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <h4 className={`font-semibold ${isPast ? 'text-neutral-600' : 'text-neutral-900'}`}>
                    {item.title}
                  </h4>
                  {item.courseName && (
                    <span
                      className="px-2 py-0.5 text-xs font-medium rounded-full text-white flex-shrink-0"
                      style={{ 
                        backgroundColor: item.color || '#9CA3AF',
                      }}
                    >
                      {item.courseName}
                    </span>
                  )}
                </div>
                
                <div className="flex items-center gap-3 text-sm">
                  <span className={`font-medium ${isPast ? 'text-neutral-500' : 'text-neutral-700'}`}>
                    {format(item.date, 'EEE, MMM d')}
                  </span>
                  <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                    isPast 
                      ? 'bg-neutral-200 text-neutral-600'
                      : getPriorityColor(item.priority).replace('bg-', 'bg-opacity-70 bg-').replace('border-', 'border-opacity-50 border-')
                  }`}>
                    {getPriorityLabel(item.priority)} Priority
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
