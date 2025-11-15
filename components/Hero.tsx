'use client';

import React from 'react';
import AnimatedPreview from './AnimatedPreview';

export default function Hero() {
  const scrollToFeatures = () => {
    const firstFeature = document.getElementById('syllabus-calendar-section');
    if (firstFeature) {
      firstFeature.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  return (
    <section className="max-w-6xl mx-auto px-6 py-16">
      <div className="relative">
        {/* Grid layout for desktop */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          {/* Left Side - Hero Text */}
          <div className="space-y-6">
            <h1 className="text-4xl lg:text-5xl font-bold text-neutral-900">
              Your Academic Co-Pilot
            </h1>
            
            <p className="text-xl text-neutral-700">
              Turn messy syllabi into a clear, AI-powered plan for your semester.
            </p>
            
            <p className="text-neutral-600 leading-relaxed">
              Upload your syllabi once and let your co-pilot handle the rest — deadlines, grades, 
              and study plans all organized for you in one calm space.
            </p>
          </div>

          {/* Right Side - Animated Preview */}
          <div className="lg:block hidden">
            <AnimatedPreview />
          </div>
        </div>

        {/* Mobile preview - shows below button on mobile */}
        <div className="lg:hidden mt-8">
          <AnimatedPreview />
        </div>

        {/* CTA Button - positioned below the grid */}
        <div className="flex justify-center mt-12">
          <button 
            onClick={scrollToFeatures}
            className="px-8 py-4 bg-neutral-100 text-neutral-900 rounded-lg font-medium shadow-lg hover:bg-neutral-200 hover:shadow-xl transition-all duration-200 border border-neutral-200"
          >
            See how it works
          </button>
        </div>
      </div>
    </section>
  );
}
