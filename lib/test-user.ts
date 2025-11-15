import { prisma } from './prisma';

export const TEST_USER_ID = 'test-user-123';
export const TEST_USER_EMAIL = 'test@example.com';

/**
 * Ensures the test user exists in the database.
 * Returns the user record, creating it if necessary.
 */
export async function ensureTestUser() {
  let user = await prisma.user.findUnique({
    where: { id: TEST_USER_ID },
  });

  if (!user) {
    // Check if user with email exists (migration scenario)
    const existingUser = await prisma.user.findUnique({
      where: { email: TEST_USER_EMAIL },
    });

    if (existingUser) {
      return existingUser;
    }

    // Create test user
    user = await prisma.user.create({
      data: {
        id: TEST_USER_ID,
        email: TEST_USER_EMAIL,
        name: 'Test User',
      },
    });
  }

  return user;
}

