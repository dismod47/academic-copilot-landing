export interface Course {
  id: string;
  name: string;
  code: string;
  color: string;
  syllabusText?: string;
  gradeCategories?: GradeCategory[];
}

export interface CalendarEvent {
  id: number;
  title: string;
  date: string;
  description?: string;
  courseId: string;
}

export interface GradeCategory {
  id: string;
  name: string;
  weight: number;
  currentScore: number;
  isCompleted: boolean;
}

