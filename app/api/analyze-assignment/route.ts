import { NextRequest, NextResponse } from 'next/server';
import { GoogleGenerativeAI } from '@google/generative-ai';

interface DifficultyAnalysis {
  difficulty: number;
  estimatedTime: string;
  keyConcepts: string[];
  suggestedSteps: string[];
  quickStartOutline: string;
}

export async function POST(request: NextRequest) {
  try {
    const { assignmentPrompt } = await request.json();

    if (!assignmentPrompt || assignmentPrompt.trim().length === 0) {
      return NextResponse.json(
        { error: 'No assignment prompt provided' },
        { status: 400 }
      );
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.error('[analyze-assignment] GEMINI_API_KEY not found in environment');
      return NextResponse.json(
        { error: 'API key not configured' },
        { status: 500 }
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

    const prompt = `Analyze the following assignment prompt and provide a detailed breakdown in JSON format.

Assignment Prompt:
${assignmentPrompt}

Please provide your analysis in the following JSON structure:
{
  "difficulty": <number from 1-10>,
  "estimatedTime": "<estimated time as a string, e.g., '4-6 hours', '2-3 days', etc.>",
  "keyConcepts": ["<concept 1>", "<concept 2>", ...],
  "suggestedSteps": ["<step 1>", "<step 2>", ...],
  "quickStartOutline": "<a brief outline for getting started>"
}

Be specific and helpful. Focus on:
- Difficulty should reflect the overall complexity (1 = very easy, 10 = very challenging)
- Estimated time should be realistic based on the scope
- Key concepts should identify main topics/subjects needed
- Suggested steps should be actionable and in order
- Quick start outline should give a high-level roadmap

Return ONLY valid JSON, no additional text.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    // Parse the JSON response
    let analysis: DifficultyAnalysis;
    try {
      // Clean up the response in case there's markdown formatting
      const cleanedText = text.trim().replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      analysis = JSON.parse(cleanedText);
    } catch (parseError) {
      console.error('[analyze-assignment] Failed to parse JSON response:', text);
      return NextResponse.json(
        { error: 'Failed to parse AI response' },
        { status: 500 }
      );
    }

    // Validate and normalize the response
    if (typeof analysis.difficulty !== 'number') {
      analysis.difficulty = 5;
    } else {
      analysis.difficulty = Math.max(1, Math.min(10, Math.round(analysis.difficulty)));
    }

    if (!analysis.estimatedTime) {
      analysis.estimatedTime = 'Unknown';
    }

    if (!Array.isArray(analysis.keyConcepts)) {
      analysis.keyConcepts = [];
    }

    if (!Array.isArray(analysis.suggestedSteps)) {
      analysis.suggestedSteps = [];
    }

    if (!analysis.quickStartOutline) {
      analysis.quickStartOutline = 'No outline provided.';
    }

    return NextResponse.json({ analysis });
  } catch (error) {
    console.error('[analyze-assignment] Error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'An error occurred' },
      { status: 500 }
    );
  }
}
