import { NextRequest, NextResponse } from 'next/server';
import { getCurrentUser } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

// GET - Fetch all saved assignment analyses for the current user
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    console.log('[assignment-analyses] Fetching analyses for user:', user.id);

    const analyses = await prisma.assignmentAnalysis.findMany({
      where: {
        userId: user.id,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    console.log('[assignment-analyses] Found', analyses.length, 'analyses for user');

    return NextResponse.json({ analyses });
  } catch (error) {
    console.error('[assignment-analyses] GET Error:', error);
    console.error('[assignment-analyses] Error details:', error instanceof Error ? error.message : String(error));
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to fetch analyses' },
      { status: 500 }
    );
  }
}

// POST - Save a new assignment analysis
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { assignmentPrompt, difficulty, estimatedTime, keyConcepts, suggestedSteps, quickStartOutline } = await request.json();

    if (!assignmentPrompt || typeof difficulty !== 'number' || !estimatedTime) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    console.log('[assignment-analyses] Saving analysis for user:', user.id);
    console.log('[assignment-analyses] Analysis data:', {
      assignmentPrompt: assignmentPrompt.substring(0, 50) + '...',
      difficulty,
      estimatedTime,
      keyConceptsCount: keyConcepts?.length || 0,
      suggestedStepsCount: suggestedSteps?.length || 0,
    });

    const analysis = await prisma.assignmentAnalysis.create({
      data: {
        userId: user.id,
        assignmentPrompt,
        difficulty: Math.round(difficulty),
        estimatedTime,
        keyConcepts: Array.isArray(keyConcepts) ? keyConcepts : [],
        suggestedSteps: Array.isArray(suggestedSteps) ? suggestedSteps : [],
        quickStartOutline: quickStartOutline || '',
      },
    });

    console.log('[assignment-analyses] Analysis saved successfully with ID:', analysis.id);

    return NextResponse.json({ analysis });
  } catch (error) {
    console.error('[assignment-analyses] POST Error:', error);
    console.error('[assignment-analyses] Error details:', error instanceof Error ? error.message : String(error));
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to save analysis' },
      { status: 500 }
    );
  }
}
