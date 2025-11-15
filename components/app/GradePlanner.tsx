'use client';

import React, { useState } from 'react';

export default function GradePlanner() {
  const [currentGrade, setCurrentGrade] = useState<string>('');
  const [gradeWanted, setGradeWanted] = useState<string>('');
  const [finalWorth, setFinalWorth] = useState<string>('');
  const [passingGrade, setPassingGrade] = useState<string>('');

  const calculateGradeNeeded = () => {
    const current = parseFloat(currentGrade);
    const wanted = parseFloat(gradeWanted);
    const finalWeight = parseFloat(finalWorth);

    // Validation
    if (isNaN(current) || isNaN(wanted) || isNaN(finalWeight)) {
      return null;
    }

    if (finalWeight <= 0 || finalWeight > 100) {
      return null;
    }

    if (current < 0 || current > 100 || wanted < 0 || wanted > 100) {
      return null;
    }

    // Calculate current points earned (before final)
    const currentWeight = 100 - finalWeight;
    const currentPointsEarned = (current * currentWeight) / 100;

    // Calculate points needed to reach desired grade
    const pointsNeeded = wanted - currentPointsEarned;

    // Calculate grade needed on final
    const gradeNeededOnFinal = (pointsNeeded / finalWeight) * 100;

    return gradeNeededOnFinal;
  };

  const calculatePassingGrade = () => {
    const current = parseFloat(currentGrade);
    const finalWeight = parseFloat(finalWorth);
    const passGrade = parseFloat(passingGrade);

    // Validation
    if (isNaN(current) || isNaN(finalWeight) || isNaN(passGrade)) {
      return null;
    }

    if (finalWeight <= 0 || finalWeight > 100) {
      return null;
    }

    if (current < 0 || current > 100 || passGrade < 0 || passGrade > 100) {
      return null;
    }

    // Calculate current points earned (before final)
    const currentWeight = 100 - finalWeight;
    const currentPointsEarned = (current * currentWeight) / 100;

    // Calculate points needed to reach passing grade
    const pointsNeeded = passGrade - currentPointsEarned;

    // Calculate grade needed on final
    const gradeNeededOnFinal = (pointsNeeded / finalWeight) * 100;

    return gradeNeededOnFinal;
  };

  const gradeNeededForWanted = calculateGradeNeeded();
  const gradeNeededForPassing = passingGrade ? calculatePassingGrade() : null;

  const getGradeLetter = (percentage: number): string => {
    if (percentage >= 97) return 'A+';
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 65) return 'D';
    return 'F';
  };

  const isValid = (value: string): boolean => {
    const num = parseFloat(value);
    return !isNaN(num) && num >= 0 && num <= 100;
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-neutral-900 mb-2">
          Grade Planner
        </h2>
        <p className="text-neutral-600">
          Calculate what grade you need on your final exam to reach your target grade.
        </p>
      </div>

      {/* Input Fields */}
      <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm space-y-4">
        <div className="space-y-2">
          <label htmlFor="current-grade" className="block text-sm font-medium text-neutral-700">
            Current Grade (%)
          </label>
          <input
            id="current-grade"
            type="number"
            value={currentGrade}
            onChange={(e) => setCurrentGrade(e.target.value)}
            placeholder="e.g., 85"
            min="0"
            max="100"
            step="0.1"
            className="w-full px-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-neutral-900"
          />
          {currentGrade && !isValid(currentGrade) && (
            <p className="text-sm text-red-600">Please enter a number between 0 and 100</p>
          )}
        </div>

        <div className="space-y-2">
          <label htmlFor="grade-wanted" className="block text-sm font-medium text-neutral-700">
            Grade Wanted (%)
          </label>
          <input
            id="grade-wanted"
            type="number"
            value={gradeWanted}
            onChange={(e) => setGradeWanted(e.target.value)}
            placeholder="e.g., 90"
            min="0"
            max="100"
            step="0.1"
            className="w-full px-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-neutral-900"
          />
          {gradeWanted && !isValid(gradeWanted) && (
            <p className="text-sm text-red-600">Please enter a number between 0 and 100</p>
          )}
        </div>

        <div className="space-y-2">
          <label htmlFor="final-worth" className="block text-sm font-medium text-neutral-700">
            What the Final is Worth (%)
          </label>
          <input
            id="final-worth"
            type="number"
            value={finalWorth}
            onChange={(e) => setFinalWorth(e.target.value)}
            placeholder="e.g., 40"
            min="0"
            max="100"
            step="0.1"
            className="w-full px-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-neutral-900"
          />
          {finalWorth && (parseFloat(finalWorth) <= 0 || parseFloat(finalWorth) > 100) && (
            <p className="text-sm text-red-600">Please enter a number between 0 and 100</p>
          )}
        </div>

        <div className="space-y-2">
          <label htmlFor="passing-grade" className="block text-sm font-medium text-neutral-700">
            Grade Needed to Pass (%)
            <span className="text-xs font-normal text-neutral-500 ml-2">(Optional)</span>
          </label>
          <input
            id="passing-grade"
            type="number"
            value={passingGrade}
            onChange={(e) => setPassingGrade(e.target.value)}
            placeholder="e.g., 70"
            min="0"
            max="100"
            step="0.1"
            className="w-full px-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-neutral-900"
          />
          {passingGrade && !isValid(passingGrade) && (
            <p className="text-sm text-red-600">Please enter a number between 0 and 100</p>
          )}
        </div>
      </div>

      {/* Results */}
      {gradeNeededForWanted !== null && (
        <div className="bg-gradient-to-br from-blue-50 to-purple-50 border-2 border-blue-300 rounded-xl p-6 shadow-sm">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4">
            To get {gradeWanted}% overall
          </h3>
          
          {gradeNeededForWanted < 0 ? (
            <div className="space-y-2">
              <p className="text-lg font-bold text-green-700">
                🎉 You've already exceeded your target!
              </p>
              <p className="text-neutral-700">
                Your current grade of <strong>{currentGrade}%</strong> is already enough to achieve {gradeWanted}% overall, 
                even if you get 0% on the final exam.
              </p>
            </div>
          ) : gradeNeededForWanted > 100 ? (
            <div className="space-y-2">
              <p className="text-lg font-bold text-red-700">
                ⚠️ Target not achievable
              </p>
              <p className="text-neutral-700">
                You would need <strong>{gradeNeededForWanted.toFixed(2)}%</strong> on the final exam to reach {gradeWanted}% overall, 
                which is not possible.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="flex items-baseline gap-2">
                <span className="text-4xl font-bold text-blue-600">
                  {gradeNeededForWanted.toFixed(2)}%
                </span>
                <span className="text-xl text-neutral-600">
                  ({getGradeLetter(gradeNeededForWanted)})
                </span>
              </div>
              <p className="text-neutral-700">
                You need to score <strong>{gradeNeededForWanted.toFixed(2)}%</strong> on the final exam 
                to achieve an overall grade of <strong>{gradeWanted}%</strong>.
              </p>
            </div>
          )}
        </div>
      )}

      {gradeNeededForPassing !== null && passingGrade && (
        <div className="bg-gradient-to-br from-green-50 to-emerald-50 border-2 border-green-300 rounded-xl p-6 shadow-sm">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4">
            To pass with {passingGrade}%
          </h3>
          
          {gradeNeededForPassing < 0 ? (
            <div className="space-y-2">
              <p className="text-lg font-bold text-green-700">
                ✅ You're already passing!
              </p>
              <p className="text-neutral-700">
                Your current grade of <strong>{currentGrade}%</strong> is already enough to pass with {passingGrade}%, 
                even if you get 0% on the final exam.
              </p>
            </div>
          ) : gradeNeededForPassing > 100 ? (
            <div className="space-y-2">
              <p className="text-lg font-bold text-red-700">
                ⚠️ Passing grade not achievable
              </p>
              <p className="text-neutral-700">
                You would need <strong>{gradeNeededForPassing.toFixed(2)}%</strong> on the final exam to pass with {passingGrade}%, 
                which is not possible.
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="flex items-baseline gap-2">
                <span className="text-4xl font-bold text-green-600">
                  {gradeNeededForPassing.toFixed(2)}%
                </span>
                <span className="text-xl text-neutral-600">
                  ({getGradeLetter(gradeNeededForPassing)})
                </span>
              </div>
              <p className="text-neutral-700">
                You need to score <strong>{gradeNeededForPassing.toFixed(2)}%</strong> on the final exam 
                to pass with an overall grade of <strong>{passingGrade}%</strong>.
              </p>
            </div>
          )}
        </div>
      )}

      {/* Info Box */}
      {currentGrade && finalWorth && parseFloat(finalWorth) > 0 && (
        <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-4">
          <p className="text-sm text-neutral-600">
            <strong>Current calculation:</strong> Your current grade ({currentGrade}%) represents{' '}
            <strong>{100 - parseFloat(finalWorth)}%</strong> of your total grade. 
            The final exam represents <strong>{finalWorth}%</strong> of your total grade.
          </p>
        </div>
      )}
    </div>
  );
}