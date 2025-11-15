import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getCurrentUser } from '@/lib/auth';

// PUT /api/events/[id] - Update an event
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const user = await getCurrentUser();

    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const { id } = await params;
    const body = await request.json();
    const { title, description, type, date, courseId, weightPercent } = body;

    // Verify event belongs to authenticated user's course
    const existingEvent = await prisma.event.findFirst({
      where: {
        id,
        course: {
          userId: user.id,
        },
      },
    });

    if (!existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    // If courseId is being changed, verify new course belongs to authenticated user
    if (courseId && courseId !== existingEvent.courseId) {
      const course = await prisma.course.findFirst({
        where: { id: courseId, userId: user.id },
      });

      if (!course) {
        return NextResponse.json(
          { error: 'Course not found' },
          { status: 400 }
        );
      }
    }

    const event = await prisma.event.update({
      where: { id },
      data: {
        title,
        description: description || null,
        type: type || existingEvent.type,
        date: date ? new Date(date) : existingEvent.date,
        courseId: courseId || existingEvent.courseId,
        weightPercent: weightPercent !== undefined ? weightPercent : existingEvent.weightPercent,
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
    });

    // Transform event to match app format
    const transformedEvent = {
      id: event.id,
      courseId: event.courseId,
      title: event.title,
      description: event.description || null,
      type: event.type,
      date: event.date.toISOString().split('T')[0],
      weightPercent: event.weightPercent,
    };

    return NextResponse.json({ event: transformedEvent });
  } catch (error: any) {
    console.error('[API] Error updating event:', error);
    return NextResponse.json(
      { error: 'Failed to update event' },
      { status: 500 }
    );
  }
}

// DELETE /api/events/[id] - Delete an event
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const user = await getCurrentUser();

    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    const { id } = await params;

    // Verify event belongs to authenticated user's course
    const existingEvent = await prisma.event.findFirst({
      where: {
        id,
        course: {
          userId: user.id,
        },
      },
    });

    if (!existingEvent) {
      return NextResponse.json(
        { error: 'Event not found' },
        { status: 404 }
      );
    }

    await prisma.event.delete({
      where: { id },
    });

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error('[API] Error deleting event:', error);
    return NextResponse.json(
      { error: 'Failed to delete event' },
      { status: 500 }
    );
  }
}

