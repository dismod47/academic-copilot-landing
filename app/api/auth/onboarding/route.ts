import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getCurrentUser } from '@/lib/auth';

// GET /api/auth/onboarding - Check if user has completed onboarding
export async function GET() {
  try {
    const user = await getCurrentUser();

    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Fetch full user to get onboarding status
    const fullUser = await prisma.user.findUnique({
      where: { id: user.id },
      select: {
        hasCompletedOnboarding: true,
      },
    });

    return NextResponse.json({
      hasCompletedOnboarding: fullUser?.hasCompletedOnboarding || false,
    });
  } catch (error: any) {
    console.error('[API] Error checking onboarding status:', error);
    return NextResponse.json(
      { error: 'Failed to check onboarding status' },
      { status: 500 }
    );
  }
}

// POST /api/auth/onboarding - Mark onboarding as complete
export async function POST() {
  try {
    const user = await getCurrentUser();

    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    // Update user to mark onboarding as complete
    await prisma.user.update({
      where: { id: user.id },
      data: {
        hasCompletedOnboarding: true,
      },
    });

    return NextResponse.json({
      success: true,
      message: 'Onboarding marked as complete',
    });
  } catch (error: any) {
    console.error('[API] Error completing onboarding:', error);
    return NextResponse.json(
      { error: 'Failed to complete onboarding' },
      { status: 500 }
    );
  }
}

