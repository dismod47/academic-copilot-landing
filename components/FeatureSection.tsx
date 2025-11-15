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
