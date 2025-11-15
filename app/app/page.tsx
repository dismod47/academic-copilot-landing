'use client';

import React, { useState, useEffect } from 'react';
import AppHeader from '@/components/app/AppHeader';
import YourCourses from '@/components/app/YourCourses';
import Calendar from '@/components/app/Calendar';
import GradePlanner from '@/components/app/GradePlanner';
import EventModal from '@/components/app/EventModal';
import OnboardingModal from '@/components/app/OnboardingModal';
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
  const [loading, setLoading] = useState(true);
  const [authenticated, setAuthenticated] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [onboardingChecked, setOnboardingChecked] = useState(false);

  // Check authentication on mount
  useEffect(() => {
    checkAuth();
  }, []);

  // Check onboarding status when authenticated
  useEffect(() => {
    if (authenticated) {
      checkOnboardingStatus();
      loadCourses();
    }
  }, [authenticated]);

  const checkOnboardingStatus = async () => {
    try {
      const response = await fetch('/api/auth/onboarding');
      const data = await response.json();
      
      if (data.hasCompletedOnboarding === false) {
        setShowOnboarding(true);
      }
      setOnboardingChecked(true);
    } catch (error) {
      console.error('[AppPage] Failed to check onboarding status:', error);
      setOnboardingChecked(true);
    }
  };

  const handleOnboardingComplete = async () => {
    try {
      await fetch('/api/auth/onboarding', {
        method: 'POST',
      });
      setShowOnboarding(false);
    } catch (error) {
      console.error('[AppPage] Failed to complete onboarding:', error);
      // Still hide the modal even if API call fails
      setShowOnboarding(false);
    }
  };

  const handleOnboardingSkip = async () => {
    try {
      await fetch('/api/auth/onboarding', {
        method: 'POST',
      });
      setShowOnboarding(false);
    } catch (error) {
      console.error('[AppPage] Failed to skip onboarding:', error);
      // Still hide the modal even if API call fails
      setShowOnboarding(false);
    }
  };

  // Load events when selectedCourse changes
  useEffect(() => {
    if (authenticated) {
      loadEvents();
    }
  }, [selectedCourse, authenticated]);

  const checkAuth = async () => {
    try {
      const response = await fetch('/api/auth/session');
      const data = await response.json();
      
      if (data.user) {
        setAuthenticated(true);
      } else {
        // Not authenticated, redirect to home
        window.location.href = '/';
      }
    } catch (error) {
      console.error('[AppPage] Failed to check auth:', error);
      window.location.href = '/';
    } finally {
      setLoading(false);
    }
  };

  const loadCourses = async () => {
    try {
      const response = await fetch('/api/courses');
      const data = await response.json();
      
      if (data.courses) {
        // Transform database courses to match app types
        const transformedCourses: Course[] = data.courses.map((c: any) => ({
          id: c.id,
          name: c.name,
          code: c.code,
          color: c.color || '#3B82F6',
          syllabusText: c.rawSyllabusText || '',
          gradeCategories: c.gradeCategories?.map((gc: any) => ({
            id: gc.id,
            name: gc.name,
            weight: gc.weightPercent,
            currentScore: gc.currentScore || 0,
            isCompleted: gc.isCompleted,
          })),
        }));
        
        setCourses(transformedCourses);
      }
    } catch (error) {
      console.error('[AppPage] Failed to load courses:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadEvents = async () => {
    try {
      const courseId = selectedCourse === 'all' ? '' : selectedCourse;
      const url = courseId ? `/api/events?courseId=${courseId}` : '/api/events';
      
      const response = await fetch(url);
      const data = await response.json();
      
      if (data.events) {
        // Transform database events to match app types
        const transformedEvents: CalendarEvent[] = data.events.map((e: any) => ({
          id: e.id,
          title: e.title,
          date: e.date,
          description: e.description || '',
          courseId: e.courseId,
          type: e.type,
          weightPercent: e.weightPercent,
        }));
        
        setEvents(transformedEvents);
      }
    } catch (error) {
      console.error('[AppPage] Failed to load events:', error);
    }
  };

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

    try {
      // Create course in database
      const courseResponse = await fetch('/api/courses', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: courseData.name,
          code: courseData.code,
          color: courseData.color,
          rawSyllabusText: syllabusText || null,
        }),
      });

      const courseData_result = await courseResponse.json();
      if (!courseData_result.course) {
        throw new Error('Failed to create course');
      }

      const newCourseId = courseData_result.course.id;

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
            // Save events to database
            const eventsResponse = await fetch('/api/events', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                events: data.events.map((event: any) => ({
                  courseId: newCourseId,
                  title: event.title,
                  description: event.description || '',
                  type: 'other',
                  date: event.date,
                  weightPercent: null,
                })),
              }),
            });

            if (eventsResponse.ok) {
              console.log('[AppPage] Saved calendar events to database');
              await loadEvents(); // Reload events
            }
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
            // Save grade categories to database
            const gradesResponse = await fetch('/api/grade-categories', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                courseId: newCourseId,
                categories: data.categories.map((cat: any) => ({
                  name: cat.name,
                  weight: cat.weight,
                  currentScore: 0,
                  isCompleted: false,
                })),
              }),
            });

            if (gradesResponse.ok) {
              console.log('[AppPage] Saved grade categories to database');
            }
          }
        } catch (error) {
          console.error('[AppPage] Failed to parse grade categories:', error);
        }
      }

      // Reload courses to get the new course with relationships
      await loadCourses();
    } catch (error) {
      console.error('[AppPage] Failed to add course:', error);
      throw error;
    }
  };

  const handleEditCourse = async (
    id: string,
    courseData: Omit<Course, 'id'>,
    syllabusText: string,
    parseCalendar: boolean,
    parseGrades: boolean
  ) => {
    console.log('[AppPage] Editing course:', id, { parseCalendar, parseGrades });

    try {
      // Update course in database
      const courseResponse = await fetch(`/api/courses/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: courseData.name,
          code: courseData.code,
          color: courseData.color,
          rawSyllabusText: syllabusText || null,
        }),
      });

      if (!courseResponse.ok) {
        throw new Error('Failed to update course');
      }

      // Re-parse calendar if requested
      if (parseCalendar && syllabusText.trim()) {
        console.log('[AppPage] Re-parsing calendar...');
        // Delete old events for this course
        const oldEvents = events.filter(e => e.courseId === id);
        for (const event of oldEvents) {
          await fetch(`/api/events/${event.id}`, { method: 'DELETE' });
        }

        try {
          const response = await fetch('/api/parse-syllabus', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ syllabusText }),
          });

          const data = await response.json();
          if (data.events && data.events.length > 0) {
            // Save new events to database
            const eventsResponse = await fetch('/api/events', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                events: data.events.map((event: any) => ({
                  courseId: id,
                  title: event.title,
                  description: event.description || '',
                  type: 'other',
                  date: event.date,
                  weightPercent: null,
                })),
              }),
            });

            if (eventsResponse.ok) {
              await loadEvents(); // Reload events
            }
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
            // Save grade categories to database (replaces existing)
            const gradesResponse = await fetch('/api/grade-categories', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                courseId: id,
                categories: data.categories.map((cat: any) => ({
                  name: cat.name,
                  weight: cat.weight,
                  currentScore: 0,
                  isCompleted: false,
                })),
              }),
            });

            if (gradesResponse.ok) {
              console.log('[AppPage] Updated grade categories in database');
            }
          }
        } catch (error) {
          console.error('[AppPage] Failed to parse grade categories:', error);
        }
      }

      // Reload courses to get updated data
      await loadCourses();
    } catch (error) {
      console.error('[AppPage] Failed to edit course:', error);
      throw error;
    }
  };

  const handleDeleteCourse = async (id: string) => {
    try {
      const response = await fetch(`/api/courses/${id}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        // Reload courses and events
        await loadCourses();
        await loadEvents();
      }
    } catch (error) {
      console.error('[AppPage] Failed to delete course:', error);
    }
  };

  const handleSaveEvent = async (event: CalendarEvent) => {
    try {
      const existingEvent = events.find(e => e.id === event.id);
      
      if (existingEvent) {
        // Update existing event
        const response = await fetch(`/api/events/${event.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            title: event.title,
            description: event.description || '',
            type: event.type || 'other',
            date: event.date,
            courseId: event.courseId,
            weightPercent: event.weightPercent || null,
          }),
        });

        if (response.ok) {
          await loadEvents();
        } else {
          const errorData = await response.json();
          console.error('[AppPage] Failed to update event:', errorData);
          alert(`Failed to update event: ${errorData.error || 'Unknown error'}`);
        }
      } else {
        // Create new event
        const response = await fetch('/api/events', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            events: [{
              courseId: event.courseId || null, // Allow null for "Other" events
              title: event.title,
              description: event.description || '',
              type: event.type || 'other',
              date: event.date,
              weightPercent: event.weightPercent || null,
            }],
          }),
        });

        const responseData = await response.json();
        
        if (response.ok) {
          await loadEvents();
        } else {
          console.error('[AppPage] Failed to create event:', responseData);
          alert(`Failed to create event: ${responseData.error || 'Unknown error'}`);
        }
      }
    } catch (error: any) {
      console.error('[AppPage] Failed to save event:', error);
      alert(`Failed to save event: ${error?.message || 'Unknown error'}`);
    }
  };

  const handleDeleteEvent = async (id: string) => {
    try {
      const response = await fetch(`/api/events/${id}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        await loadEvents();
      }
    } catch (error) {
      console.error('[AppPage] Failed to delete event:', error);
    }
  };

  const handleRemoveAllEvents = async () => {
    try {
      if (selectedCourse === 'all') {
        // Delete all events for user
        const eventsToDelete = events;
        for (const event of eventsToDelete) {
          await fetch(`/api/events/${event.id}`, { method: 'DELETE' });
        }
      } else if (selectedCourse === 'other') {
        // Delete "Other" events (events without course)
        const eventsToDelete = events.filter(e => !e.courseId);
        for (const event of eventsToDelete) {
          await fetch(`/api/events/${event.id}`, { method: 'DELETE' });
        }
      } else {
        // Delete events for selected course
        const eventsToDelete = events.filter(e => e.courseId === selectedCourse);
        for (const event of eventsToDelete) {
          await fetch(`/api/events/${event.id}`, { method: 'DELETE' });
        }
      }
      
      await loadEvents();
    } catch (error) {
      console.error('[AppPage] Failed to remove all events:', error);
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
        {loading || !authenticated ? (
          <div className="flex items-center justify-center py-12">
            <div className="text-neutral-600">Loading...</div>
          </div>
        ) : (
          <>
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
                  onAddEvent={(date) => {
                    console.log('[AppPage] onAddEvent called with date:', date);
                    setEventModal({ date });
                  }}
                  onRemoveAllEvents={handleRemoveAllEvents}
                />
              </div>
            )}

            {activeTab === 'grades' && <GradePlanner courses={courses} />}
          </>
        )}
      </main>

      {/* Event Modal */}
      {eventModal && (
        <EventModal
          event={eventModal.event ?? null}
          date={eventModal.date}
          courses={courses}
          onSave={handleSaveEvent}
          onDelete={handleDeleteEvent}
          onClose={() => {
            console.log('[AppPage] Closing event modal');
            setEventModal(null);
          }}
        />
      )}

      {/* Onboarding Modal */}
      {showOnboarding && onboardingChecked && (
        <OnboardingModal
          isOpen={showOnboarding}
          onComplete={handleOnboardingComplete}
          onSkip={handleOnboardingSkip}
        />
      )}
    </div>
  );
}
