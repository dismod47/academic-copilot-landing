import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getCurrentUser } from '@/lib/auth';

// GET /api/grade-categories?courseId=xxx - Get grade categories for a course
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();

    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const { searchParams } = new URL(request.url);
    const courseId = searchParams.get('courseId');

    if (!courseId) {
      return NextResponse.json(
        { error: 'courseId is required' },
        { status: 400 }
      );
    }

    // Verify course belongs to authenticated user
    const course = await prisma.course.findFirst({
      where: { id: courseId, userId: user.id },
    });

    if (!course) {
      return NextResponse.json(
        { error: 'Course not found' },
        { status: 404 }
      );
    }

    const gradeCategories = await prisma.gradeCategory.findMany({
      where: { courseId },
      orderBy: { id: 'asc' },
    });

    return NextResponse.json({ gradeCategories });
  } catch (error: any) {
    console.error('[API] Error fetching grade categories:', error);
    return NextResponse.json(
      { error: 'Failed to fetch grade categories' },
      { status: 500 }
    );
  }
}

// POST /api/grade-categories - Create grade categories (bulk)
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();

    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const body = await request.json();
    const { courseId, categories } = body;

    if (!courseId || !categories || !Array.isArray(categories)) {
      return NextResponse.json(
        { error: 'courseId and categories array are required' },
        { status: 400 }
      );
    }

    // Verify course belongs to authenticated user
    const course = await prisma.course.findFirst({
      where: { id: courseId, userId: user.id },
    });

    if (!course) {
      return NextResponse.json(
        { error: 'Course not found' },
        { status: 404 }
      );
    }

    // Delete existing grade categories for this course (replace mode)
    await prisma.gradeCategory.deleteMany({
      where: { courseId },
    });

    // Create new grade categories
    const created = await prisma.gradeCategory.createMany({
      data: categories.map((cat: any) => ({
        courseId,
        name: cat.name,
        weightPercent: cat.weight,
        currentScore: cat.currentScore || null,
        isCompleted: cat.isCompleted || false,
      })),
    });

    // Fetch created categories
    const gradeCategories = await prisma.gradeCategory.findMany({
      where: { courseId },
      orderBy: { id: 'asc' },
    });

    return NextResponse.json({ gradeCategories }, { status: 201 });
  } catch (error: any) {
    console.error('[API] Error creating grade categories:', error);
    return NextResponse.json(
      { error: 'Failed to create grade categories' },
      { status: 500 }
    );
  }
}

