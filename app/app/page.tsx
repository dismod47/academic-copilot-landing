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
    console.log('[AppPage] Adding course:', { 
      courseName: courseData.name, 
      syllabusLength: syllabusText.length, 
      parseCalendar, 
      parseGrades 
    });

    const newCourse: Course = {
      id: Date.now().toString(),
      ...courseData,
      syllabusText: syllabusText,
    };

    let parsedEvents: CalendarEvent[] = [];
    let parsedGrades: GradeCategory[] = [];

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
          const maxId = events.length > 0 ? Math.max(...events.map(e => e.id)) : 0;
          parsedEvents = data.events.map((event: any, index: number) => ({
            id: maxId + index + 1,
            title: event.title,
            date: event.date,
            description: event.description || '',
            courseId: newCourse.id,
          }));
          console.log('[AppPage] Created calendar events:', parsedEvents);
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
          parsedGrades = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
          console.log('[AppPage] Created grade categories:', parsedGrades);
          
          // CRITICAL: Store the parsed grades on the course object
          newCourse.gradeCategories = parsedGrades;
          console.log('[AppPage] Assigned gradeCategories to course:', newCourse.gradeCategories);
        } else {
          console.log('[AppPage] No grade categories in response');
        }
      } catch (error) {
        console.error('[AppPage] Failed to parse grade categories:', error);
      }
    }

    // Add course to state
    console.log('[AppPage] Final course object before adding to state:', newCourse);
    setCourses(prev => {
      const updated = [...prev, newCourse];
      console.log('[AppPage] Updated courses state:', updated);
      return updated;
    });

    // Add events to state
    if (parsedEvents.length > 0) {
      console.log('[AppPage] Adding events to state:', parsedEvents);
      setEvents(prev => {
        const updated = [...prev, ...parsedEvents];
        console.log('[AppPage] Updated events state:', updated);
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

    console.log('[AppPage] Editing course:', id, { parseCalendar, parseGrades });

    const updatedCourse: Course = {
      id,
      ...courseData,
      syllabusText: syllabusText,
      gradeCategories: existingCourse.gradeCategories,
    };

    // Re-parse calendar if requested
    if (parseCalendar && syllabusText.trim()) {
      console.log('[AppPage] Re-parsing calendar...');
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
          updatedCourse.gradeCategories = data.categories.map((cat: any, index: number) => ({
            id: (index + 1).toString(),
            name: cat.name,
            weight: cat.weight,
            currentScore: 0,
            isCompleted: false,
          }));
          console.log('[AppPage] Updated gradeCategories:', updatedCourse.gradeCategories);
        }
      } catch (error) {
        console.error('[AppPage] Failed to parse grade categories:', error);
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
