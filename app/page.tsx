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
            id="syllabus-calendar-section"
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
            comingSoon={true}
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
