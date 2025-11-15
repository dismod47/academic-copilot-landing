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
