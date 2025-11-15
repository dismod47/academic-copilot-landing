import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

interface GradeCategory {
  name: string;
  weight: number;
}

export async function POST(request: NextRequest) {
  try {
    const { syllabusText } = await request.json();

    console.log('[parse-grades] Received request with syllabus length:', syllabusText?.length);

    if (!syllabusText || syllabusText.trim().length === 0) {
      return NextResponse.json({
        categories: [],
        error: 'No syllabus text provided'
      });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error('[parse-grades] GEMINI_API_KEY not found in environment');
      return NextResponse.json({
        categories: [],
        error: 'API key not configured'
      });
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `You are a syllabus grading breakdown parser. Extract the grading breakdown from the following course syllabus.

For each grading category (homework, quizzes, exams, projects, participation, attendance, etc.), extract:
- name: A clear, concise name for the category
- weight: The percentage weight (as a number, e.g., 20 for 20%)

Return ONLY a valid JSON array of categories. If no grading breakdown can be found, return an empty array [].

Example format:
[
  {
    "name": "Homework",
    "weight": 20
  },
  {
    "name": "Quizzes",
    "weight": 15
  },
  {
    "name": "Midterm Exam",
    "weight": 25
  },
  {
    "name": "Final Exam",
    "weight": 40
  }
]

IMPORTANT: 
- Look for sections like "Grading", "Grade Breakdown", "Assessment", "Course Grades", "Evaluation"
- Only extract categories with clear percentage weights
- Weights should be numbers (not strings like "20%")
- The weights should ideally sum to 100, but extract what you find
- Do NOT include categories without weights
- Return ONLY the JSON array, no other text
- Do not wrap in markdown code blocks

Syllabus:
${syllabusText}`;

    console.log('[parse-grades] Calling Gemini API...');
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    console.log('[parse-grades] Gemini response:', text);

    let categories: GradeCategory[] = [];
    try {
      const cleanedText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      console.log('[parse-grades] Cleaned text:', cleanedText);
      
      categories = JSON.parse(cleanedText);
      console.log('[parse-grades] Parsed categories:', categories);
      
      if (!Array.isArray(categories)) {
        throw new Error('Response is not an array');
      }

      categories = categories.filter(cat => 
        cat.name && 
        typeof cat.weight === 'number' &&
        cat.weight > 0
      );
      
      console.log('[parse-grades] Filtered categories:', categories);
    } catch (parseError) {
      console.error('[parse-grades] Failed to parse AI response:', parseError);
      console.error('[parse-grades] Raw text:', text);
      return NextResponse.json({
        categories: [],
        error: 'Could not parse grade breakdown from this syllabus.'
      });
    }

    if (categories.length === 0) {
      console.log('[parse-grades] No categories found');
      return NextResponse.json({
        categories: [],
        error: 'No grading breakdown found in the syllabus.'
      });
    }

    console.log('[parse-grades] Success! Returning categories:', categories);
    return NextResponse.json({ categories });
  } catch (error) {
    console.error('[parse-grades] Error:', error);
    return NextResponse.json({
      categories: [],
      error: 'Could not parse grade breakdown from this syllabus.'
    });
  }
}
