import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getCurrentUser } from '@/lib/auth';

// GET /api/events - Get all events for authenticated user (optionally filtered by courseId)
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

    const where: any = {
      course: {
        userId: user.id,
      },
    };

    if (courseId && courseId !== 'all') {
      where.courseId = courseId;
    }

    const events = await prisma.event.findMany({
      where,
      include: {
        course: {
          select: {
            id: true,
            name: true,
            code: true,
            color: true,
          },
        },
      },
      orderBy: { date: 'asc' },
    });

    // Transform events to match app format (date as ISO string)
    const transformedEvents = events.map((e) => ({
      id: e.id,
      courseId: e.courseId,
      title: e.title,
      description: e.description || null,
      type: e.type,
      date: e.date.toISOString().split('T')[0], // Convert to YYYY-MM-DD format
      weightPercent: e.weightPercent,
    }));

    return NextResponse.json({ events: transformedEvents });
  } catch (error: any) {
    console.error('[API] Error fetching events:', error);
    return NextResponse.json(
      { error: 'Failed to fetch events' },
      { status: 500 }
    );
  }
}

// POST /api/events - Create events (bulk or single)
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
    const { events } = body; // Can be array or single event

    if (!events || (Array.isArray(events) && events.length === 0)) {
      return NextResponse.json(
        { error: 'Events array is required' },
        { status: 400 }
      );
    }

    const eventsArray = Array.isArray(events) ? events : [events];

    // Verify all courses belong to authenticated user
    const courseIds = [...new Set(eventsArray.map((e: any) => e.courseId))];
    const courses = await prisma.course.findMany({
      where: {
        id: { in: courseIds },
        userId: user.id,
      },
    });

    if (courses.length !== courseIds.length) {
      return NextResponse.json(
        { error: 'One or more courses not found' },
        { status: 400 }
      );
    }

    const createdEvents = await prisma.event.createMany({
      data: eventsArray.map((event: any) => ({
        courseId: event.courseId,
        title: event.title,
        description: event.description || null,
        type: event.type || 'other',
        date: new Date(event.date),
        weightPercent: event.weightPercent || null,
      })),
    });

    // Fetch created events with course info
    const allEvents = await prisma.event.findMany({
      where: {
        course: {
          userId: user.id,
        },
      },
      include: {
        course: {
          select: {
            id: true,
            name: true,
            code: true,
            color: true,
          },
        },
      },
      orderBy: { date: 'asc' },
    });

    // Transform events to match app format (date as YYYY-MM-DD)
    const transformedEvents = allEvents.map((e) => ({
      id: e.id,
      courseId: e.courseId,
      title: e.title,
      description: e.description || null,
      type: e.type,
      date: e.date.toISOString().split('T')[0],
      weightPercent: e.weightPercent,
    }));

    return NextResponse.json({ events: transformedEvents }, { status: 201 });
  } catch (error: any) {
    console.error('[API] Error creating events:', error);
    return NextResponse.json(
      { error: 'Failed to create events' },
      { status: 500 }
    );
  }
}

