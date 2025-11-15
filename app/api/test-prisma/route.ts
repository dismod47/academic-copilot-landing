import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    // Test the connection by querying the database
    const result = await prisma.$queryRaw`SELECT 1 as test`;
    
    // Test all the new models
    const userCount = await prisma.user.count();
    const courseCount = await prisma.course.count();
    const eventCount = await prisma.event.count();
    const gradeCategoryCount = await prisma.gradeCategory.count();
    
    // Test a simple query on each model
    const users = await prisma.user.findMany({ take: 5 });
    const courses = await prisma.course.findMany({ take: 5 });
    const events = await prisma.event.findMany({ take: 5 });
    const gradeCategories = await prisma.gradeCategory.findMany({ take: 5 });

    return NextResponse.json({
      success: true,
      message: 'Prisma is working correctly with all core models!',
      database: {
        connected: true,
        models: {
          users: { count: userCount, sample: users },
          courses: { count: courseCount, sample: courses },
          events: { count: eventCount, sample: events },
          gradeCategories: { count: gradeCategoryCount, sample: gradeCategories },
        },
      },
    });
  } catch (error: any) {
    console.error('Prisma connection error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error.message,
        details: 'Failed to connect to database or execute query',
      },
      { status: 500 }
    );
  }
}

