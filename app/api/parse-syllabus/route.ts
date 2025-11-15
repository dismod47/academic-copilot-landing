import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

interface Event {
  title: string;
  date: string;
  description?: string;
}

export async function POST(request: NextRequest) {
  try {
    const { syllabusText } = await request.json();

    if (!syllabusText || syllabusText.trim().length === 0) {
      return NextResponse.json({
        events: [],
        error: 'No syllabus text provided'
      });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return NextResponse.json({
        events: [],
        error: 'API key not configured'
      });
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `You are a syllabus parser. Extract ALL dated events from the following course syllabus.

For each event (exam, homework, quiz, project, major reading, assignment, etc.), extract:
- title: A clear, concise title for the event
- date: The date in YYYY-MM-DD format
- description: Optional brief description

Return ONLY a valid JSON array of events. If no events can be found, return an empty array [].

Example format:
[
  {
    "title": "Homework 1 Due",
    "date": "2025-10-15",
    "description": "Chapter 1-3 problems"
  },
  {
    "title": "Midterm Exam",
    "date": "2025-11-05"
  }
]

IMPORTANT: 
- Only extract events with clear, specific dates
- Convert all dates to YYYY-MM-DD format
- If a date is relative (like "Week 3"), try to calculate the actual date based on semester context
- Do NOT include vague or undated items
- Return ONLY the JSON array, no other text

Syllabus:
${syllabusText}`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();
    
    if (!text || text.trim().length === 0) {
      console.error('Empty response from Gemini API');
      return NextResponse.json({
        events: [],
        error: 'Could not parse events from this syllabus.'
      });
    }

    // Try to extract JSON from the response
    let events: Event[] = [];
    try {
      // Remove markdown code blocks if present
      const cleanedText = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      events = JSON.parse(cleanedText);
      
      if (!Array.isArray(events)) {
        throw new Error('Response is not an array');
      }

      // Validate event structure
      events = events.filter(event => 
        event.title && 
        event.date && 
        /^\d{4}-\d{2}-\d{2}$/.test(event.date)
      );
    } catch (parseError) {
      console.error('Failed to parse AI response:', text);
      return NextResponse.json({
        events: [],
        error: 'Could not parse events from this syllabus.'
      });
    }

    if (events.length === 0) {
      return NextResponse.json({
        events: [],
        error: 'No dated events found in the syllabus. Please check that dates are clearly specified.'
      });
    }

    return NextResponse.json({ events });
  } catch (error) {
    console.error('Error parsing syllabus:', error);
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error('Error details:', errorMessage);
    return NextResponse.json({
      events: [],
      error: 'Could not parse events from this syllabus.'
    });
  }
}
