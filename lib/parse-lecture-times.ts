/**
 * Parses lecture times string and generates recurring lecture events
 * Example formats:
 * - "Wednesday Fridays, 1:00 - 3:30 PM"
 * - "Monday Wednesday Friday, 9:00 AM - 10:30 AM"
 * - "Tuesday Thursday, 2:00 PM - 3:30 PM"
 */

import { addDays, setHours, setMinutes, parseISO, format, startOfWeek, getDay } from 'date-fns';

interface LectureTime {
  days: number[]; // 0 = Sunday, 1 = Monday, etc.
  startTime: string; // HH:mm format
  endTime: string; // HH:mm format
}

const DAY_NAMES: { [key: string]: number } = {
  'sunday': 0,
  'sun': 0,
  'monday': 1,
  'mon': 1,
  'tuesday': 2,
  'tue': 2,
  'wednesday': 3,
  'wed': 3,
  'thursday': 4,
  'thu': 4,
  'friday': 5,
  'fri': 5,
  'saturday': 6,
  'sat': 6,
};

export function parseLectureTimes(lectureTimes: string): LectureTime[] | null {
  if (!lectureTimes || !lectureTimes.trim()) {
    return null;
  }

  try {
    // Normalize the input
    let text = lectureTimes.toLowerCase().trim();
    
    // Extract time range (e.g., "1:00 - 3:30 PM" or "9:00 AM - 10:30 AM")
    const timePattern = /(\d{1,2}):(\d{2})\s*(AM|PM)?\s*[-–—]\s*(\d{1,2}):(\d{2})\s*(AM|PM)?/;
    const timeMatch = text.match(timePattern);
    
    if (!timeMatch) {
      return null;
    }

    const [, startHour, startMin, startPeriod, endHour, endMin, endPeriod] = timeMatch;
    
    // Convert to 24-hour format
    let startHour24 = parseInt(startHour);
    let endHour24 = parseInt(endHour);
    
    if (startPeriod === 'pm' && startHour24 !== 12) {
      startHour24 += 12;
    } else if (startPeriod === 'am' && startHour24 === 12) {
      startHour24 = 0;
    }
    
    if (endPeriod === 'pm' && endHour24 !== 12) {
      endHour24 += 12;
    } else if (endPeriod === 'am' && endHour24 === 12) {
      endHour24 = 0;
    }
    
    // If no period specified, assume PM if hour is 1-11, else AM
    if (!startPeriod && !endPeriod) {
      if (startHour24 < 12 && startHour24 >= 1) {
        startHour24 += 12;
      }
      if (endHour24 < 12 && endHour24 >= 1) {
        endHour24 += 12;
      }
    }

    const startTime = `${startHour24.toString().padStart(2, '0')}:${startMin}`;
    const endTime = `${endHour24.toString().padStart(2, '0')}:${endMin}`;

    // Extract days (e.g., "Wednesday Fridays" or "Monday Wednesday Friday")
    const daysPart = text.substring(0, timeMatch.index || 0).trim();
    
    // Parse day names
    const days: number[] = [];
    const dayWords = daysPart.split(/[,\s]+/).filter(word => word.length > 0);
    
    for (const word of dayWords) {
      const dayName = word.toLowerCase();
      if (DAY_NAMES[dayName] !== undefined) {
        const dayNum = DAY_NAMES[dayName];
        if (!days.includes(dayNum)) {
          days.push(dayNum);
        }
      }
    }

    if (days.length === 0) {
      return null;
    }

    return [{
      days: days.sort(),
      startTime,
      endTime,
    }];
  } catch (error) {
    console.error('Failed to parse lecture times:', error);
    return null;
  }
}

/**
 * Generates lecture events for a semester
 * @param courseId - The course ID
 * @param courseName - The course name (for event title)
 * @param lectureTimes - The lecture times string
 * @param semesterStart - Start date of the semester (defaults to current date if not provided)
 * @param semesterEnd - End date of the semester (defaults to 4 months from start)
 */
export function generateLectureEvents(
  courseId: string,
  courseName: string,
  lectureTimes: string,
  semesterStart?: Date,
  semesterEnd?: Date
): Array<{ title: string; date: string; type: string; courseId: string; description?: string }> {
  const parsed = parseLectureTimes(lectureTimes);
  
  if (!parsed || parsed.length === 0) {
    return [];
  }

  const start = semesterStart || new Date();
  const end = semesterEnd || addDays(start, 120); // Default to 4 months
  
  const events: Array<{ title: string; date: string; type: string; courseId: string; description?: string }> = [];
  const lectureTime = parsed[0];
  
  // Get the first occurrence of each day in the semester
  const currentDate = new Date(start);
  const endDate = new Date(end);
  
  while (currentDate <= endDate) {
    const dayOfWeek = currentDate.getDay();
    
    if (lectureTime.days.includes(dayOfWeek)) {
      // Create event for this day
      const [startHour, startMin] = lectureTime.startTime.split(':').map(Number);
      const [endHour, endMin] = lectureTime.endTime.split(':').map(Number);
      
      const eventDate = setMinutes(setHours(new Date(currentDate), startHour), startMin);
      
      const title = `Lecture - ${courseName}`;
      const endTime = setMinutes(setHours(new Date(currentDate), endHour), endMin);
      const description = `${format(eventDate, 'h:mm a')} - ${format(endTime, 'h:mm a')}`;
      
      // Format as ISO string for API (yyyy-MM-ddTHH:mm:ss)
      const dateISO = format(eventDate, "yyyy-MM-dd'T'HH:mm:ss");
      
      events.push({
        title,
        date: dateISO,
        type: 'lecture',
        courseId,
        description,
      });
    }
    
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  return events;
}
