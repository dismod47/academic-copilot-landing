'use client';

import React, { useState } from 'react';

interface DifficultyAnalysis {
  difficulty: number;
  estimatedTime: string;
  keyConcepts: string[];
  suggestedSteps: string[];
  quickStartOutline: string;
}

export default function AssignmentDifficultyPredictor() {
  const [assignmentPrompt, setAssignmentPrompt] = useState('');
  const [analysis, setAnalysis] = useState<DifficultyAnalysis | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAnalyze = async () => {
    if (!assignmentPrompt.trim()) {
      setError('Please paste an assignment prompt first');
      return;
    }

    setLoading(true);
    setError(null);
    setAnalysis(null);

    try {
      const response = await fetch('/api/analyze-assignment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ assignmentPrompt }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Failed to analyze assignment');
      }

      setAnalysis(data.analysis);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h2 className="text-2xl font-semibold text-neutral-900 mb-2">
          Assignment Difficulty Predictor
        </h2>
        <p className="text-neutral-600">
          Paste your assignment prompt below and get an AI-powered analysis of difficulty, time requirements, and suggested steps.
        </p>
      </div>

      {/* Input Section */}
      <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm">
        <label htmlFor="assignment-prompt" className="block text-sm font-medium text-neutral-700 mb-2">
          Assignment Prompt
        </label>
        <textarea
          id="assignment-prompt"
          value={assignmentPrompt}
          onChange={(e) => setAssignmentPrompt(e.target.value)}
          placeholder="Paste your assignment prompt here..."
          className="w-full min-h-[200px] px-4 py-3 border border-neutral-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-y text-neutral-900"
        />
        <button
          onClick={handleAnalyze}
          disabled={loading || !assignmentPrompt.trim()}
          className="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:bg-neutral-300 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? 'Analyzing...' : 'Analyze Assignment'}
        </button>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
          {error}
        </div>
      )}

      {/* Analysis Results */}
      {analysis && (
        <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm space-y-6">
          <h3 className="text-xl font-semibold text-neutral-900">Analysis Results</h3>

          {/* Difficulty Score */}
          <div className="border-b border-neutral-200 pb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-neutral-700">Difficulty</span>
              <span className="text-3xl font-bold text-blue-600">{analysis.difficulty}/10</span>
            </div>
            <div className="w-full bg-neutral-200 rounded-full h-3">
              <div
                className="bg-blue-600 h-3 rounded-full transition-all duration-500"
                style={{ width: `${(analysis.difficulty / 10) * 100}%` }}
              />
            </div>
          </div>

          {/* Estimated Time */}
          <div className="border-b border-neutral-200 pb-4">
            <span className="text-sm font-medium text-neutral-700 block mb-2">Estimated Time Needed</span>
            <span className="text-lg text-neutral-900">{analysis.estimatedTime}</span>
          </div>

          {/* Key Concepts */}
          <div className="border-b border-neutral-200 pb-4">
            <span className="text-sm font-medium text-neutral-700 block mb-3">Key Concepts Involved</span>
            <div className="flex flex-wrap gap-2">
              {analysis.keyConcepts.map((concept, index) => (
                <span
                  key={index}
                  className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm border border-blue-200"
                >
                  {concept}
                </span>
              ))}
            </div>
          </div>

          {/* Suggested Steps */}
          <div className="border-b border-neutral-200 pb-4">
            <span className="text-sm font-medium text-neutral-700 block mb-3">Suggested Steps</span>
            <ol className="list-decimal list-inside space-y-2 text-neutral-700">
              {analysis.suggestedSteps.map((step, index) => (
                <li key={index} className="pl-2">{step}</li>
              ))}
            </ol>
          </div>

          {/* Quick Start Outline */}
          <div>
            <span className="text-sm font-medium text-neutral-700 block mb-3">Quick Start Outline</span>
            <div className="bg-neutral-50 border border-neutral-200 rounded-lg p-4 text-neutral-700 whitespace-pre-wrap">
              {analysis.quickStartOutline}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
