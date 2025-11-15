import React from 'react';
import FeatureCard from './FeatureCard';

const features = [
  {
    title: 'Syllabus → Calendar automation',
    description: 'Upload your syllabus and instantly generate a clean, color-coded calendar for your entire semester.',
  },
  {
    title: 'Grade predictions',
    description: 'See exactly what you need on upcoming exams and assignments to hit your target grade.',
  },
  {
    title: 'AI study planner',
    description: 'Turn deadlines into a realistic study plan that fits your week instead of overwhelming it.',
  },
  {
    title: 'Dashboard organization',
    description: 'Keep all your courses, tasks, and grades in one calm, simple dashboard.',
  },
];

export default function FeatureGrid() {
  return (
    <section className="max-w-6xl mx-auto px-6 py-16">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {features.map((feature, index) => (
          <FeatureCard
            key={index}
            title={feature.title}
            description={feature.description}
          />
        ))}
      </div>
    </section>
  );
}
