'use client';

import React, { useState } from 'react';

interface OnboardingModalProps {
  isOpen: boolean;
  onComplete: () => void;
  onSkip: () => void;
}

const slides = [
  {
    title: 'Welcome to Your Academic Co-Pilot',
    body: 'Turn messy syllabi into a clear, organized plan for your entire semester. Stay on top of deadlines and know exactly what you need to achieve your goals.',
    cta: 'Next',
  },
  {
    title: 'Add Your Courses',
    body: 'In the Your Courses tab, add each course and attach a syllabus. Choose to parse your syllabus automatically into deadlines and grade weights using AI.',
    cta: 'Next',
  },
  {
    title: 'See Everything on Your Calendar',
    body: 'The Calendar tab shows all your deadlines from parsed syllabi in one place. Filter by course to see what\'s coming up next.',
    cta: 'Next',
  },
  {
    title: 'Know What You Need to Get',
    body: 'The Grade Planner tab lets you see what scores you need on upcoming assignments to hit your target grade, using the parsed grade weights from your syllabi.',
    cta: 'Got it, let\'s start',
  },
];

export default function OnboardingModal({
  isOpen,
  onComplete,
  onSkip,
}: OnboardingModalProps) {
  const [currentSlide, setCurrentSlide] = useState(0);

  if (!isOpen) return null;

  const handleNext = () => {
    if (currentSlide < slides.length - 1) {
      setCurrentSlide(currentSlide + 1);
    } else {
      onComplete();
    }
  };

  const handlePrevious = () => {
    if (currentSlide > 0) {
      setCurrentSlide(currentSlide - 1);
    }
  };

  const handleSkip = () => {
    onSkip();
  };

  const slide = slides[currentSlide];
  const isLastSlide = currentSlide === slides.length - 1;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-[90] p-4">
      <div className="bg-white rounded-xl shadow-xl max-w-md w-full p-6 relative">
        {/* Close button */}
        <button
          onClick={handleSkip}
          className="absolute top-4 right-4 text-neutral-400 hover:text-neutral-600 transition-colors"
          aria-label="Skip onboarding"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>

        {/* Progress indicator */}
        <div className="flex justify-center gap-2 mb-6">
          {slides.map((_, index) => (
            <div
              key={index}
              className={`h-2 rounded-full transition-all ${
                index === currentSlide
                  ? 'bg-blue-500 w-8'
                  : index < currentSlide
                  ? 'bg-blue-300 w-2'
                  : 'bg-neutral-200 w-2'
              }`}
            />
          ))}
        </div>

        {/* Slide content */}
        <div className="mb-6 min-h-[200px]">
          <h2 className="text-2xl font-bold text-neutral-900 mb-4">
            {slide.title}
          </h2>
          <p className="text-neutral-700 leading-relaxed text-lg">
            {slide.body}
          </p>
        </div>

        {/* Navigation buttons */}
        <div className="flex items-center justify-between gap-3">
          <button
            onClick={handlePrevious}
            disabled={currentSlide === 0}
            className={`px-4 py-2 rounded-lg font-medium transition-colors ${
              currentSlide === 0
                ? 'text-neutral-400 cursor-not-allowed'
                : 'text-neutral-700 hover:bg-neutral-100'
            }`}
          >
            Previous
          </button>

          <div className="flex gap-3">
            {!isLastSlide && (
              <button
                onClick={handleSkip}
                className="px-4 py-2 text-neutral-600 hover:text-neutral-900 font-medium transition-colors"
              >
                Skip
              </button>
            )}
            <button
              onClick={handleNext}
              className="px-6 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-colors"
            >
              {slide.cta}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

