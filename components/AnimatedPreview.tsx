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
