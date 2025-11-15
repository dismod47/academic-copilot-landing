export interface Course {
  id: string;
  name: string;
  code: string;
  color: string;
  syllabusText?: string;
  gradeCategories?: GradeCategory[];
}

export interface CalendarEvent {
  id: string;
  title: string;
  date: string;
  description?: string;
  courseId?: string; // Optional - can be null for "Other" events
  type?: string;
  weightPercent?: number;
}

export interface GradeCategory {
  id: string;
  name: string;
  weight: number;
  currentScore: number;
  isCompleted: boolean;
}

