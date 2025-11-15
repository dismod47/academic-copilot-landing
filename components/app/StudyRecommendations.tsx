'use client';

import React, { useMemo, useState, useEffect } from 'react';
import { 
  startOfWeek, 
  endOfWeek, 
  format, 
  parseISO,
  isWithinInterval,
  differenceInDays,
  addDays
} from 'date-fns';
import { CalendarEvent, Course } from '@/types/app';

interface StudyRecommendationsProps {
  events: CalendarEvent[];
  courses: Course[];
}

interface StudyRecommendation {
  id: string; // event id + date for unique key
  courseName: string;
  topic: string;
  priority: number;
  recommendedHours: number;
  reason: string;
  eventDate: Date;
  eventType: string;
  weightPercent?: number;
  eventId: string;
}

export default function StudyRecommendations({ events, courses }: StudyRecommendationsProps) {
  const today = new Date();
  const weekStart = startOfWeek(today, { weekStartsOn: 0 });
  const weekEnd = endOfWeek(today, { weekStartsOn: 0 });
  
  // Load custom study hours from localStorage
  const [customHours, setCustomHours] = useState<Record<string, number>>({});
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editValue, setEditValue] = useState<string>('');

  useEffect(() => {
    try {
      const saved = localStorage.getItem('study-hours-customizations');
      if (saved) {
        setCustomHours(JSON.parse(saved));
      }
    } catch (error) {
      console.error('Failed to load custom study hours:', error);
    }
  }, []);

  const saveCustomHours = (id: string, hours: number) => {
    const updated = { ...customHours, [id]: hours };
    setCustomHours(updated);
    try {
      localStorage.setItem('study-hours-customizations', JSON.stringify(updated));
    } catch (error) {
      console.error('Failed to save custom study hours:', error);
    }
  };
  
  // Get events for this week and next week (14 days ahead)
  const upcomingEvents = useMemo(() => {
    const twoWeeksOut = addDays(today, 14);
    return events.filter(event => {
      const eventDate = parseISO(event.date);
      return isWithinInterval(eventDate, { start: today, end: twoWeeksOut });
    });
  }, [events, today]);

  // Calculate study recommendations
  const recommendations = useMemo(() => {
    const recs: StudyRecommendation[] = [];
    const courseMap = new Map(courses.map(c => [c.id, c]));

    upcomingEvents.forEach(event => {
      const eventDate = parseISO(event.date);
      const daysUntil = differenceInDays(eventDate, today);
      const course = event.courseId ? courseMap.get(event.courseId) : null;
      const courseName = course?.name || 'Other';
      
      const type = (event.type || '').toLowerCase();
      const title = (event.title || '').toLowerCase();
      const combinedText = `${type} ${title}`;
      
      // Determine priority score (higher = more important)
      let priority = 1;
      let recommendedHours = 1;
      let reason = '';
      
      // Check if it's an exam/test/quiz
      if (combinedText.includes('exam') || combinedText.includes('test') || combinedText.includes('final')) {
        // High weight, soon: highest priority
        if (daysUntil <= 3) {
          priority = 10;
          recommendedHours = Math.max(3, (event.weightPercent || 20) / 10); // At least 3 hours, more for higher weight
          reason = `Exam in ${daysUntil} day${daysUntil !== 1 ? 's' : ''} - Critical priority`;
        } else if (daysUntil <= 7) {
          priority = 8;
          recommendedHours = Math.max(2, (event.weightPercent || 20) / 15);
          reason = `Exam in ${daysUntil} days - High priority`;
        } else {
          priority = 6;
          recommendedHours = Math.max(1.5, (event.weightPercent || 20) / 20);
          reason = `Exam in ${daysUntil} days - Plan ahead`;
        }
      } else if (combinedText.includes('quiz') || combinedText.includes('midterm')) {
        if (daysUntil <= 2) {
          priority = 8;
          recommendedHours = Math.max(2, (event.weightPercent || 15) / 12);
          reason = `Quiz in ${daysUntil} day${daysUntil !== 1 ? 's' : ''} - High priority`;
        } else if (daysUntil <= 5) {
          priority = 6;
          recommendedHours = Math.max(1.5, (event.weightPercent || 15) / 18);
          reason = `Quiz in ${daysUntil} days - Medium-high priority`;
        } else {
          priority = 4;
          recommendedHours = Math.max(1, (event.weightPercent || 15) / 25);
          reason = `Quiz in ${daysUntil} days - Medium priority`;
        }
      } else if (combinedText.includes('project')) {
        if (daysUntil <= 3) {
          priority = 5;
          recommendedHours = Math.max(2, (event.weightPercent || 15) / 15);
          reason = `Project due in ${daysUntil} day${daysUntil !== 1 ? 's' : ''}`;
        } else if (daysUntil <= 7) {
          priority = 3;
          recommendedHours = Math.max(1.5, (event.weightPercent || 15) / 20);
          reason = `Project due in ${daysUntil} days`;
        } else {
          priority = 2;
          recommendedHours = 1;
          reason = `Project due in ${daysUntil} days - Start planning`;
        }
      } else if (combinedText.includes('assignment') || combinedText.includes('homework') || combinedText.includes('hw')) {
        if (daysUntil <= 2) {
          priority = 4;
          recommendedHours = 1.5;
          reason = `Assignment due in ${daysUntil} day${daysUntil !== 1 ? 's' : ''}`;
        } else if (daysUntil <= 5) {
          priority = 2;
          recommendedHours = 1;
          reason = `Assignment due in ${daysUntil} days`;
        } else {
          priority = 1;
          recommendedHours = 0.5;
          reason = `Assignment due in ${daysUntil} days`;
        }
      } else {
        // Other/reading
        if (daysUntil <= 2) {
          priority = 3;
          recommendedHours = 1;
          reason = `Due in ${daysUntil} day${daysUntil !== 1 ? 's' : ''}`;
        } else {
          priority = 1;
          recommendedHours = 0.5;
          reason = `Due in ${daysUntil} days`;
        }
      }
      
      // Boost priority based on grade weight
      if (event.weightPercent && event.weightPercent > 25) {
        priority += 1;
        recommendedHours += 0.5;
      }
      
      const recommendationId = `${event.id}-${event.date}`;
      const baseHours = Math.round(recommendedHours * 2) / 2; // Round to nearest 0.5
      const finalHours = customHours[recommendationId] !== undefined 
        ? customHours[recommendationId] 
        : baseHours;

      recs.push({
        id: recommendationId,
        courseName,
        topic: event.title,
        priority,
        recommendedHours: finalHours,
        reason,
        eventDate,
        eventType: event.type || 'other',
        weightPercent: event.weightPercent,
        eventId: event.id,
      });
    });

    // Sort by priority (highest first), then by date (soonest first)
    return recs.sort((a, b) => {
      if (b.priority !== a.priority) {
        return b.priority - a.priority;
      }
      return a.eventDate.getTime() - b.eventDate.getTime();
    });
  }, [upcomingEvents, courses, today, customHours]);

  // Calculate total recommended hours
  const totalHours = useMemo(() => {
    return recommendations.reduce((sum, rec) => sum + rec.recommendedHours, 0);
  }, [recommendations]);

  // Group by course for summary
  const courseSummary = useMemo(() => {
    const summary = new Map<string, { hours: number; highPriority: number }>();
    
    recommendations.forEach(rec => {
      const existing = summary.get(rec.courseName) || { hours: 0, highPriority: 0 };
      existing.hours += rec.recommendedHours;
      if (rec.priority >= 7) {
        existing.highPriority += 1;
      }
      summary.set(rec.courseName, existing);
    });
    
    return Array.from(summary.entries()).map(([course, data]) => ({
      courseName: course,
      ...data,
    })).sort((a, b) => b.hours - a.hours);
  }, [recommendations]);

  const getPriorityColor = (priority: number): string => {
    if (priority >= 8) return 'bg-red-100 text-red-800 border-red-300';
    if (priority >= 6) return 'bg-orange-100 text-orange-800 border-orange-300';
    if (priority >= 4) return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    return 'bg-blue-100 text-blue-800 border-blue-300';
  };

  const getPriorityLabel = (priority: number): string => {
    if (priority >= 8) return 'Critical';
    if (priority >= 6) return 'High';
    if (priority >= 4) return 'Medium';
    return 'Low';
  };

  if (recommendations.length === 0) {
    return (
      <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm mt-6">
        <h3 className="text-xl font-semibold text-neutral-900 mb-4">
          Study Session Recommendations
        </h3>
        <p className="text-neutral-600 text-center py-4">
          No upcoming events in the next 2 weeks. Great time for review and catching up! 📚
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm mt-6">
      <h3 className="text-xl font-semibold text-neutral-900 mb-2">
        Study Session Recommendations
      </h3>
      <p className="text-sm text-neutral-600 mb-6">
        Personalized study priorities based on upcoming deadlines, exam dates, and grade weights
      </p>

      {/* Summary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 border border-blue-200 rounded-lg p-4">
          <p className="text-sm text-blue-700 font-medium mb-1">Total Study Time</p>
          <p className="text-2xl font-bold text-blue-900">{totalHours.toFixed(1)} hours</p>
          <p className="text-xs text-blue-600 mt-1">Recommended this week</p>
        </div>
        
        <div className="bg-gradient-to-br from-red-50 to-red-100 border border-red-200 rounded-lg p-4">
          <p className="text-sm text-red-700 font-medium mb-1">High Priority Items</p>
          <p className="text-2xl font-bold text-red-900">
            {recommendations.filter(r => r.priority >= 7).length}
          </p>
          <p className="text-xs text-red-600 mt-1">Need immediate attention</p>
        </div>
        
        <div className="bg-gradient-to-br from-green-50 to-green-100 border border-green-200 rounded-lg p-4">
          <p className="text-sm text-green-700 font-medium mb-1">Courses to Focus On</p>
          <p className="text-2xl font-bold text-green-900">{courseSummary.length}</p>
          <p className="text-xs text-green-600 mt-1">Active courses this week</p>
        </div>
      </div>

      {/* Course Breakdown */}
      {courseSummary.length > 0 && (
        <div className="mb-6">
          <h4 className="text-sm font-semibold text-neutral-700 mb-3">Time Allocation by Course</h4>
          <div className="space-y-2">
            {courseSummary.map(({ courseName, hours, highPriority }) => (
              <div key={courseName} className="flex items-center justify-between p-3 bg-neutral-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <span className="font-medium text-neutral-900">{courseName}</span>
                  {highPriority > 0 && (
                    <span className="px-2 py-0.5 bg-red-100 text-red-700 text-xs font-medium rounded">
                      {highPriority} urgent
                    </span>
                  )}
                </div>
                <span className="font-semibold text-neutral-700">{hours.toFixed(1)} hrs</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Detailed Recommendations */}
      <div>
        <h4 className="text-sm font-semibold text-neutral-700 mb-3">Recommended Study Plan</h4>
        <div className="space-y-3">
          {recommendations.slice(0, 8).map((rec, index) => (
            <div
              key={`${rec.courseName}-${rec.topic}-${rec.eventDate}`}
              className={`p-4 rounded-lg border-2 ${getPriorityColor(rec.priority)}`}
            >
              <div className="flex items-start justify-between gap-3 mb-2">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-semibold text-neutral-900">{rec.topic}</span>
                    {rec.weightPercent && (
                      <span className="px-2 py-0.5 bg-white bg-opacity-50 text-xs font-medium rounded">
                        {rec.weightPercent}% weight
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-neutral-700 mb-1">{rec.courseName}</p>
                  <p className="text-xs text-neutral-600">{rec.reason}</p>
                </div>
                <div className="text-right flex-shrink-0 flex flex-col items-end gap-2">
                  <div className={`px-3 py-1 rounded text-xs font-medium ${
                    rec.priority >= 8 
                      ? 'bg-red-200 text-red-900' 
                      : rec.priority >= 6
                      ? 'bg-orange-200 text-orange-900'
                      : 'bg-yellow-200 text-yellow-900'
                  }`}>
                    {getPriorityLabel(rec.priority)}
                  </div>
                  {editingId === rec.id ? (
                    <div className="flex items-center gap-2">
                      <input
                        type="number"
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        min="0"
                        max="20"
                        step="0.5"
                        className="w-16 px-2 py-1 border border-neutral-300 rounded text-sm text-neutral-900"
                        autoFocus
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            const hours = parseFloat(editValue);
                            if (!isNaN(hours) && hours >= 0 && hours <= 20) {
                              saveCustomHours(rec.id, hours);
                              setEditingId(null);
                              setEditValue('');
                            }
                          } else if (e.key === 'Escape') {
                            setEditingId(null);
                            setEditValue('');
                          }
                        }}
                        onBlur={() => {
                          const hours = parseFloat(editValue);
                          if (!isNaN(hours) && hours >= 0 && hours <= 20) {
                            saveCustomHours(rec.id, hours);
                          }
                          setEditingId(null);
                          setEditValue('');
                        }}
                      />
                      <span className="text-sm text-neutral-600">h</span>
                    </div>
                  ) : (
                    <div className="text-lg font-bold text-neutral-900">
                      {rec.recommendedHours}h
                    </div>
                  )}
                  {!editingId && (
                    <button
                      onClick={() => {
                        setEditingId(rec.id);
                        setEditValue(rec.recommendedHours.toString());
                      }}
                      className="text-xs text-blue-600 hover:text-blue-800 font-medium"
                    >
                      Edit
                    </button>
                  )}
                </div>
              </div>
              <div className="flex items-center justify-between text-xs text-neutral-600">
                <div className="flex items-center gap-2">
                  <span>📅 {format(rec.eventDate, 'MMM d, yyyy')}</span>
                  {index === 0 && (
                    <span className="px-2 py-0.5 bg-yellow-200 text-yellow-900 rounded font-medium">
                      Start here
                    </span>
                  )}
                </div>
                {customHours[rec.id] !== undefined && (
                  <span className="text-neutral-500 italic">
                    Customized
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
        
        {recommendations.length > 8 && (
          <p className="text-sm text-neutral-500 mt-4 text-center">
            + {recommendations.length - 8} more recommendations (view in calendar)
          </p>
        )}
      </div>

      {/* Study Tips */}
      <div className="mt-6 pt-6 border-t border-neutral-200">
        <h4 className="text-sm font-semibold text-neutral-700 mb-3">💡 Study Tips</h4>
        <ul className="space-y-2 text-sm text-neutral-600">
          {recommendations.filter(r => r.priority >= 8).length > 0 && (
            <li className="flex items-start gap-2">
              <span className="text-red-500 mt-0.5">•</span>
              <span>Focus on high-priority items first (red badges). These are coming soon and likely have higher grade weights.</span>
            </li>
          )}
          <li className="flex items-start gap-2">
            <span className="text-blue-500 mt-0.5">•</span>
            <span>Break study sessions into 1-2 hour blocks for better retention.</span>
          </li>
          {totalHours > 10 && (
            <li className="flex items-start gap-2">
              <span className="text-orange-500 mt-0.5">•</span>
              <span>You have {totalHours.toFixed(1)} hours of recommended study time. Consider spreading this across multiple days.</span>
            </li>
          )}
          <li className="flex items-start gap-2">
            <span className="text-green-500 mt-0.5">•</span>
            <span>Higher weighted exams and tests should get proportionally more study time.</span>
          </li>
        </ul>
      </div>
    </div>
  );
}
