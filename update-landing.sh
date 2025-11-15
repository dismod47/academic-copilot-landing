#!/usr/bin/env bash

echo "=========================================="
echo "Updating Your Academic Co-Pilot Landing Page"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Please run this script from the project root."
    exit 1
fi

echo "Step 1: Installing animation dependencies..."
echo ""
npm install framer-motion

echo ""
echo "Step 2: Creating new component files..."
echo ""

# Create components directory if it doesn't exist
mkdir -p components

# Create AnimatedPreview component
cat << 'EOF' > components/AnimatedPreview.tsx
'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

type Scene = 'syllabus' | 'grades';

export default function AnimatedPreview() {
  const [scene, setScene] = useState<Scene>('syllabus');

  useEffect(() => {
    const interval = setInterval(() => {
      setScene((prev) => (prev === 'syllabus' ? 'grades' : 'syllabus'));
    }, 6000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="relative bg-white rounded-2xl border border-neutral-200 p-8 shadow-lg min-h-[400px] overflow-hidden">
      <AnimatePresence mode="wait">
        {scene === 'syllabus' ? (
          <SyllabusScene key="syllabus" />
        ) : (
          <GradesScene key="grades" />
        )}
      </AnimatePresence>
    </div>
  );
}

function SyllabusScene() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.5 }}
      className="space-y-6"
    >
      <div>
        <p className="text-xs uppercase text-neutral-500 mb-2">Scene 1</p>
        <h3 className="text-2xl font-semibold text-neutral-900 mb-3">
          Syllabus → Smart Calendar
        </h3>
      </div>

      <div className="flex items-center justify-center gap-6 py-8">
        {/* Stacked syllabi */}
        <motion.div
          className="relative"
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.6 }}
        >
          <div className="space-y-2">
            {[0, 1, 2].map((i) => (
              <motion.div
                key={i}
                className="w-20 h-24 bg-neutral-100 border-2 border-neutral-300 rounded-lg shadow-md relative"
                initial={{ rotate: 0 }}
                animate={{ rotate: i * -5 }}
                style={{ marginLeft: i * -10 }}
              >
                <div className="p-2 space-y-1">
                  <div className="w-full h-1 bg-neutral-400 rounded"></div>
                  <div className="w-3/4 h-1 bg-neutral-300 rounded"></div>
                  <div className="w-full h-1 bg-neutral-300 rounded"></div>
                  <div className="w-1/2 h-1 bg-neutral-300 rounded"></div>
                </div>
              </motion.div>
            ))}
          </div>
          <motion.p
            className="text-xs text-neutral-600 text-center mt-2"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8 }}
          >
            Multiple syllabi
          </motion.p>
        </motion.div>

        {/* Arrow */}
        <motion.div
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 1, duration: 0.5 }}
        >
          <svg
            className="w-12 h-12 text-neutral-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 7l5 5m0 0l-5 5m5-5H6"
            />
          </svg>
        </motion.div>

        {/* Calendar */}
        <motion.div
          initial={{ x: 20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 1.4, duration: 0.6 }}
        >
          <div className="w-32 bg-white border-2 border-blue-300 rounded-lg shadow-lg p-2">
            <div className="flex justify-between mb-2">
              <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
              <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
            </div>
            <div className="grid grid-cols-4 gap-1">
              {[...Array(16)].map((_, i) => (
                <motion.div
                  key={i}
                  className={`h-3 rounded ${
                    i % 5 === 0
                      ? 'bg-blue-200'
                      : i % 3 === 0
                      ? 'bg-green-200'
                      : 'bg-neutral-100'
                  }`}
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: 1.6 + i * 0.05 }}
                ></motion.div>
              ))}
            </div>
          </div>
          <motion.p
            className="text-xs text-neutral-600 text-center mt-2"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 2.2 }}
          >
            Organized calendar
          </motion.p>
        </motion.div>
      </div>

      <motion.div
        className="bg-neutral-50 rounded-lg p-4 border border-neutral-200"
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 2.4 }}
      >
        <p className="text-sm text-neutral-600 text-center">
          All assignments, exams, and deadlines automatically organized
        </p>
      </motion.div>
    </motion.div>
  );
}

function GradesScene() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.5 }}
      className="space-y-6"
    >
      <div>
        <p className="text-xs uppercase text-neutral-500 mb-2">Scene 2</p>
        <h3 className="text-2xl font-semibold text-neutral-900 mb-3">
          Grade Predictions
        </h3>
      </div>

      <div className="space-y-4 py-4">
        {/* Assignment inputs */}
        <motion.div
          className="space-y-3"
          initial={{ x: -20, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: 0.2, duration: 0.6 }}
        >
          {[
            { label: 'Exams', value: '50%', color: 'blue' },
            { label: 'Homework', value: '30%', color: 'green' },
            { label: 'Final Project', value: '20%', color: 'purple' },
          ].map((item, i) => (
            <motion.div
              key={item.label}
              className={`flex items-center justify-between bg-${item.color}-50 border border-${item.color}-200 rounded-lg p-3`}
              initial={{ x: -20, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: 0.4 + i * 0.2 }}
            >
              <span className="text-sm font-medium text-neutral-700">
                {item.label}
              </span>
              <span className="text-sm font-semibold text-neutral-900">
                {item.value}
              </span>
            </motion.div>
          ))}
        </motion.div>

        {/* Arrow down */}
        <motion.div
          className="flex justify-center"
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 1.2, duration: 0.5 }}
        >
          <svg
            className="w-8 h-8 text-neutral-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 14l-7 7m0 0l-7-7m7 7V3"
            />
          </svg>
        </motion.div>

        {/* Result card */}
        <motion.div
          className="bg-gradient-to-br from-blue-50 to-purple-50 border-2 border-blue-300 rounded-lg p-4 shadow-lg"
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 1.6, duration: 0.6 }}
        >
          <motion.p
            className="text-sm font-semibold text-neutral-900 mb-1"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 2 }}
          >
            📊 Your target: A grade (90%)
          </motion.p>
          <motion.p
            className="text-xs text-neutral-700"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 2.2 }}
          >
            You need <span className="font-bold text-blue-600">82%</span> or
            higher on Exam 3 to stay on track.
          </motion.p>
        </motion.div>
      </div>

      <motion.div
        className="bg-neutral-50 rounded-lg p-4 border border-neutral-200"
        initial={{ y: 20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ delay: 2.4 }}
      >
        <p className="text-sm text-neutral-600 text-center">
          Know exactly what you need before every assessment
        </p>
      </motion.div>
    </motion.div>
  );
}
EOF

echo "✓ Created components/AnimatedPreview.tsx"

# Create updated Hero component
cat << 'EOF' > components/Hero.tsx
import React from 'react';
import AnimatedPreview from './AnimatedPreview';

export default function Hero() {
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

        {/* Centered CTA Button - positioned between columns on desktop */}
        <div className="flex justify-center lg:absolute lg:top-1/2 lg:left-1/2 lg:transform lg:-translate-x-1/2 lg:-translate-y-1/2 lg:z-10 mt-8 lg:mt-0">
          <button className="px-8 py-4 bg-neutral-100 text-neutral-900 rounded-lg font-medium shadow-lg hover:bg-neutral-200 hover:shadow-xl transition-all duration-200 border border-neutral-200">
            See how it works
          </button>
        </div>

        {/* Mobile preview - shows below button on mobile */}
        <div className="lg:hidden mt-8">
          <AnimatedPreview />
        </div>
      </div>
    </section>
  );
}
EOF

echo "✓ Created components/Hero.tsx"

# Create FeatureSection component for alternating layout
cat << 'EOF' > components/FeatureSection.tsx
'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { useInView } from 'framer-motion';
import { useRef } from 'react';

interface FeatureSectionProps {
  title: string;
  description: string;
  illustration: React.ReactNode;
  reverse?: boolean;
}

export default function FeatureSection({
  title,
  description,
  illustration,
  reverse = false,
}: FeatureSectionProps) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: '-100px' });

  return (
    <section ref={ref} className="max-w-6xl mx-auto px-6 py-16">
      <div
        className={`grid grid-cols-1 lg:grid-cols-2 gap-12 items-center ${
          reverse ? 'lg:grid-flow-dense' : ''
        }`}
      >
        {/* Text Content */}
        <motion.div
          className={`space-y-4 ${reverse ? 'lg:col-start-2' : ''}`}
          initial={{ opacity: 0, x: reverse ? 20 : -20 }}
          animate={isInView ? { opacity: 1, x: 0 } : { opacity: 0, x: reverse ? 20 : -20 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <div className="bg-white rounded-xl border border-neutral-200 p-8 shadow-sm">
            <h3 className="text-2xl font-semibold text-neutral-900 mb-4">
              {title}
            </h3>
            <p className="text-neutral-600 leading-relaxed text-lg">
              {description}
            </p>
          </div>
        </motion.div>

        {/* Illustration */}
        <motion.div
          className={reverse ? 'lg:col-start-1 lg:row-start-1' : ''}
          initial={{ opacity: 0, x: reverse ? -20 : 20 }}
          animate={isInView ? { opacity: 1, x: 0 } : { opacity: 0, x: reverse ? -20 : 20 }}
          transition={{ duration: 0.6, delay: 0.4 }}
        >
          {illustration}
        </motion.div>
      </div>
    </section>
  );
}
EOF

echo "✓ Created components/FeatureSection.tsx"

# Create illustration components
cat << 'EOF' > components/FeatureIllustrations.tsx
'use client';

import React from 'react';
import { motion } from 'framer-motion';

export function SyllabusCalendarIllustration() {
  return (
    <div className="bg-white rounded-2xl border border-neutral-200 p-8 shadow-lg min-h-[300px] flex items-center justify-center">
      <div className="flex items-center gap-8">
        {/* Documents stack */}
        <motion.div
          className="relative"
          initial={{ x: -30, opacity: 0 }}
          whileInView={{ x: 0, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
        >
          {[0, 1, 2].map((i) => (
            <motion.div
              key={i}
              className="w-24 h-32 bg-gradient-to-br from-neutral-50 to-neutral-100 border-2 border-neutral-300 rounded-lg shadow-md absolute"
              style={{
                left: i * 15,
                top: i * 10,
                zIndex: 3 - i,
              }}
              animate={{
                rotate: [0, -3 + i, 0],
              }}
              transition={{
                duration: 2,
                repeat: Infinity,
                delay: i * 0.2,
              }}
            >
              <div className="p-3 space-y-2">
                <div className="w-full h-2 bg-neutral-400 rounded"></div>
                <div className="w-3/4 h-1.5 bg-neutral-300 rounded"></div>
                <div className="w-full h-1.5 bg-neutral-300 rounded"></div>
                <div className="w-1/2 h-1.5 bg-neutral-300 rounded"></div>
              </div>
            </motion.div>
          ))}
        </motion.div>

        {/* Arrow */}
        <motion.div
          initial={{ scale: 0 }}
          whileInView={{ scale: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5, duration: 0.5 }}
        >
          <svg
            className="w-16 h-16 text-blue-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <motion.path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M13 7l5 5m0 0l-5 5m5-5H6"
              initial={{ pathLength: 0 }}
              whileInView={{ pathLength: 1 }}
              viewport={{ once: true }}
              transition={{ delay: 0.7, duration: 0.8 }}
            />
          </svg>
        </motion.div>

        {/* Calendar */}
        <motion.div
          initial={{ x: 30, opacity: 0 }}
          whileInView={{ x: 0, opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.3, duration: 0.8 }}
          className="relative"
        >
          <div className="w-40 bg-white border-2 border-blue-400 rounded-xl shadow-xl p-3">
            <div className="flex justify-between mb-3 pb-2 border-b border-neutral-200">
              <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
              <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
            </div>
            <div className="grid grid-cols-5 gap-1.5">
              {[...Array(20)].map((_, i) => (
                <motion.div
                  key={i}
                  className={`h-4 rounded ${
                    i % 7 === 0
                      ? 'bg-blue-300'
                      : i % 5 === 0
                      ? 'bg-green-300'
                      : i % 3 === 0
                      ? 'bg-purple-200'
                      : 'bg-neutral-100'
                  }`}
                  initial={{ opacity: 0, scale: 0 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: 1 + i * 0.03 }}
                ></motion.div>
              ))}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
}

export function GradePredictionIllustration() {
  return (
    <div className="bg-white rounded-2xl border border-neutral-200 p-8 shadow-lg min-h-[300px] flex flex-col justify-center">
      <div className="space-y-4">
        {/* Category bars */}
        {[
          { label: 'Exams', value: 85, color: 'blue', width: '85%' },
          { label: 'Homework', value: 92, color: 'green', width: '92%' },
          { label: 'Final Project', value: 0, color: 'purple', width: '0%' },
        ].map((item, i) => (
          <motion.div
            key={item.label}
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ delay: i * 0.2, duration: 0.5 }}
          >
            <div className="flex items-center justify-between mb-1">
              <span className="text-sm font-medium text-neutral-700">
                {item.label}
              </span>
              <span className="text-sm text-neutral-500">
                {item.value > 0 ? `${item.value}%` : 'Pending'}
              </span>
            </div>
            <div className="w-full h-3 bg-neutral-100 rounded-full overflow-hidden">
              <motion.div
                className={`h-full bg-${item.color}-400 rounded-full`}
                initial={{ width: '0%' }}
                whileInView={{ width: item.width }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.2 + 0.3, duration: 0.8 }}
              ></motion.div>
            </div>
          </motion.div>
        ))}

        {/* Prediction card */}
        <motion.div
          className="mt-6 bg-gradient-to-br from-blue-50 to-purple-50 border-2 border-blue-300 rounded-xl p-5 shadow-md"
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.8, duration: 0.6 }}
        >
          <p className="text-sm font-semibold text-neutral-900 mb-2">
            🎯 Target Grade: A (90%)
          </p>
          <p className="text-sm text-neutral-700">
            You need{' '}
            <span className="font-bold text-blue-600 text-lg">78%</span> or
            higher on the Final Project to achieve your goal.
          </p>
        </motion.div>
      </div>
    </div>
  );
}

export function StudyPlannerIllustration() {
  return (
    <div className="bg-white rounded-2xl border border-neutral-200 p-8 shadow-lg min-h-[300px] flex flex-col justify-center">
      <div className="space-y-4">
        {/* Unorganized tasks */}
        <motion.div
          className="space-y-2"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
        >
          <p className="text-xs uppercase text-neutral-500 mb-3">Before</p>
          {['Essay due Friday', 'Study for exam', 'Lab report', 'Read Ch. 5-7'].map(
            (task, i) => (
              <motion.div
                key={task}
                className="bg-red-50 border border-red-200 rounded-lg p-2 text-sm text-neutral-700"
                initial={{ x: Math.random() * 40 - 20, opacity: 0 }}
                whileInView={{ x: 0, opacity: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1, duration: 0.5 }}
              >
                {task}
              </motion.div>
            )
          )}
        </motion.div>

        {/* Arrow */}
        <motion.div
          className="flex justify-center py-2"
          initial={{ scale: 0 }}
          whileInView={{ scale: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5, duration: 0.3 }}
        >
          <svg
            className="w-8 h-8 text-green-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 14l-7 7m0 0l-7-7m7 7V3"
            />
          </svg>
        </motion.div>

        {/* Organized schedule */}
        <motion.div
          className="space-y-2"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.8 }}
        >
          <p className="text-xs uppercase text-neutral-500 mb-3">After</p>
          <div className="grid grid-cols-7 gap-1">
            {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day, i) => (
              <div key={i} className="text-center">
                <p className="text-xs font-medium text-neutral-600 mb-1">{day}</p>
                <motion.div
                  className={`h-16 rounded ${
                    i < 5 ? 'bg-green-200' : 'bg-neutral-100'
                  } border border-neutral-300`}
                  initial={{ scaleY: 0 }}
                  whileInView={{ scaleY: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: 1 + i * 0.1, duration: 0.4 }}
                  style={{ originY: 0 }}
                >
                  {i < 5 && (
                    <div className="p-1 text-xs text-neutral-700 font-medium">
                      {i === 0 && '📖'}
                      {i === 2 && '✍️'}
                      {i === 4 && '📚'}
                    </div>
                  )}
                </motion.div>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </div>
  );
}

export function DashboardIllustration() {
  return (
    <div className="bg-white rounded-2xl border border-neutral-200 p-8 shadow-lg min-h-[300px] flex items-center justify-center">
      <div className="w-full space-y-4">
        <motion.div
          className="grid grid-cols-2 gap-4"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
        >
          {[
            { title: 'Math 101', color: 'blue', icon: '📐' },
            { title: 'Physics 201', color: 'purple', icon: '⚛️' },
            { title: 'History 150', color: 'green', icon: '📜' },
            { title: 'CS 301', color: 'orange', icon: '💻' },
          ].map((course, i) => (
            <motion.div
              key={course.title}
              className={`bg-${course.color}-50 border-2 border-${course.color}-300 rounded-xl p-4 shadow-md`}
              initial={{ opacity: 0, scale: 0.8, rotate: Math.random() * 20 - 10 }}
              whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.15, duration: 0.5, type: 'spring' }}
            >
              <div className="text-2xl mb-2">{course.icon}</div>
              <p className="font-semibold text-neutral-900 text-sm">
                {course.title}
              </p>
              <div className="mt-2 space-y-1">
                <div className="w-full h-1.5 bg-neutral-200 rounded"></div>
                <div className="w-3/4 h-1.5 bg-neutral-200 rounded"></div>
              </div>
            </motion.div>
          ))}
        </motion.div>

        <motion.p
          className="text-center text-sm text-neutral-600 pt-2"
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.8 }}
        >
          All your courses organized in one place
        </motion.p>
      </div>
    </div>
  );
}
EOF

echo "✓ Created components/FeatureIllustrations.tsx"

# Update the main page
cat << 'EOF' > app/page.tsx
import Header from '@/components/Header';
import Hero from '@/components/Hero';
import FeatureSection from '@/components/FeatureSection';
import {
  SyllabusCalendarIllustration,
  GradePredictionIllustration,
  StudyPlannerIllustration,
  DashboardIllustration,
} from '@/components/FeatureIllustrations';

export default function Home() {
  return (
    <div className="min-h-screen">
      <Header />
      <main>
        <Hero />
        
        {/* Feature Sections with alternating layout */}
        <div className="py-8">
          <FeatureSection
            title="Syllabus → Calendar automation"
            description="Upload your syllabus and instantly generate a clean, color-coded calendar for your entire semester."
            illustration={<SyllabusCalendarIllustration />}
            reverse={false}
          />

          <FeatureSection
            title="Grade predictions"
            description="See exactly what you need on upcoming exams and assignments to hit your target grade."
            illustration={<GradePredictionIllustration />}
            reverse={true}
          />

          <FeatureSection
            title="AI study planner"
            description="Turn deadlines into a realistic study plan that fits your week instead of overwhelming it."
            illustration={<StudyPlannerIllustration />}
            reverse={false}
          />

          <FeatureSection
            title="Dashboard organization"
            description="Keep all your courses, tasks, and grades in one calm, simple dashboard."
            illustration={<DashboardIllustration />}
            reverse={true}
          />
        </div>
      </main>
    </div>
  );
}
EOF

echo "✓ Updated app/page.tsx"

echo ""
echo "=========================================="
echo "Update Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Installed framer-motion for animations"
echo "  ✓ Created AnimatedPreview component with cycling scenes"
echo "  ✓ Updated Hero with centered CTA button"
echo "  ✓ Created FeatureSection component for alternating layouts"
echo "  ✓ Created 4 animated feature illustrations"
echo "  ✓ Updated main page with new component structure"
echo ""
echo "To see your changes:"
echo "  npm run dev"
echo ""
echo "Then visit http://localhost:3000"
echo ""
