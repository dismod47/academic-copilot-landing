'use client';

import React, { useState, useEffect } from 'react';

interface DifficultyAnalysis {
  difficulty: number;
  estimatedTime: string;
  keyConcepts: string[];
  suggestedSteps: string[];
  quickStartOutline: string;
}

interface SavedAnalysis {
  id: string;
  assignmentPrompt: string;
  difficulty: number;
  estimatedTime: string;
  keyConcepts: string[];
  suggestedSteps: string[];
  quickStartOutline: string;
  createdAt: string;
}

export default function AssignmentDifficultyPredictor() {
  const [assignmentPrompt, setAssignmentPrompt] = useState('');
  const [analysis, setAnalysis] = useState<DifficultyAnalysis | null>(null);
  const [savedAnalyses, setSavedAnalyses] = useState<SavedAnalysis[]>([]);
  const [selectedAnalysis, setSelectedAnalysis] = useState<SavedAnalysis | null>(null);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load saved analyses on mount
  useEffect(() => {
    loadSavedAnalyses();
  }, []);

  const loadSavedAnalyses = async () => {
    try {
      const response = await fetch('/api/assignment-analyses');
      const data = await response.json();
      
      if (!response.ok) {
        console.error('[AssignmentDifficultyPredictor] Failed to load saved analyses:', data.error || 'Unknown error');
        setError(data.error || 'Failed to load saved analyses');
        return;
      }
      
      if (data.analyses) {
        console.log('[AssignmentDifficultyPredictor] Loaded saved analyses:', data.analyses.length);
        setSavedAnalyses(data.analyses);
      }
    } catch (err) {
      console.error('[AssignmentDifficultyPredictor] Error loading saved analyses:', err);
      setError(err instanceof Error ? err.message : 'Failed to load saved analyses');
    }
  };

  const handleAnalyze = async () => {
    if (!assignmentPrompt.trim()) {
      setError('Please paste an assignment prompt first');
      return;
    }

    setLoading(true);
    setError(null);
    setAnalysis(null);
    setSelectedAnalysis(null);

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

  const handleSave = async () => {
    if (!analysis || !assignmentPrompt.trim()) {
      setError('No analysis to save');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const saveData = {
        assignmentPrompt,
        difficulty: analysis.difficulty,
        estimatedTime: analysis.estimatedTime,
        keyConcepts: analysis.keyConcepts,
        suggestedSteps: analysis.suggestedSteps,
        quickStartOutline: analysis.quickStartOutline,
      };

      console.log('[AssignmentDifficultyPredictor] Saving analysis:', saveData);

      const response = await fetch('/api/assignment-analyses', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(saveData),
      });

      const data = await response.json();

      if (!response.ok) {
        console.error('[AssignmentDifficultyPredictor] Save failed:', data.error);
        throw new Error(data.error || 'Failed to save analysis');
      }

      console.log('[AssignmentDifficultyPredictor] Analysis saved successfully:', data.analysis);

      // Reload saved analyses
      await loadSavedAnalyses();
      
      // Clear error state
      setError(null);
      
      // Show success message
      alert('Analysis saved successfully!');
    } catch (err) {
      console.error('[AssignmentDifficultyPredictor] Error saving analysis:', err);
      setError(err instanceof Error ? err.message : 'Failed to save analysis');
    } finally {
      setSaving(false);
    }
  };

  const handleSelectAnalysis = (savedAnalysis: SavedAnalysis) => {
    setSelectedAnalysis(savedAnalysis);
    setAssignmentPrompt(savedAnalysis.assignmentPrompt);
    setAnalysis({
      difficulty: savedAnalysis.difficulty,
      estimatedTime: savedAnalysis.estimatedTime,
      keyConcepts: savedAnalysis.keyConcepts,
      suggestedSteps: savedAnalysis.suggestedSteps,
      quickStartOutline: savedAnalysis.quickStartOutline,
    });
    // Scroll to top
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDeleteAnalysis = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent triggering select when clicking delete

    if (!confirm('Are you sure you want to delete this saved analysis?')) {
      return;
    }

    try {
      const response = await fetch(`/api/assignment-analyses/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Failed to delete analysis');
      }

      // Remove from list
      setSavedAnalyses(savedAnalyses.filter(a => a.id !== id));
      
      // If it was selected, clear it
      if (selectedAnalysis?.id === id) {
        setSelectedAnalysis(null);
        setAnalysis(null);
        setAssignmentPrompt('');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete analysis');
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    });
  };

  const truncateText = (text: string, maxLength: number) => {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength) + '...';
  };

  return (
    <div className="flex gap-6">
      {/* Main Content Area */}
      <div className="flex-1 space-y-6">
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

            {/* Save Button */}
            <div className="pt-4 border-t border-neutral-200">
              <button
                onClick={handleSave}
                disabled={saving}
                className="px-6 py-2 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 disabled:bg-neutral-300 disabled:cursor-not-allowed transition-colors"
              >
                {saving ? 'Saving...' : 'Save Analysis'}
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Saved Analyses Sidebar */}
      <div className="w-80 flex-shrink-0">
        <div className="bg-white rounded-xl border border-neutral-200 p-6 shadow-sm sticky top-8">
          <h3 className="text-lg font-semibold text-neutral-900 mb-4">
            Saved Analyses ({savedAnalyses.length})
          </h3>
          
          {savedAnalyses.length === 0 ? (
            <p className="text-sm text-neutral-500">
              No saved analyses yet. Save an analysis to see it here.
            </p>
          ) : (
            <div className="space-y-3 max-h-[calc(100vh-200px)] overflow-y-auto">
              {savedAnalyses.map((savedAnalysis) => (
                <div
                  key={savedAnalysis.id}
                  onClick={() => handleSelectAnalysis(savedAnalysis)}
                  className={`p-4 rounded-lg border cursor-pointer transition-all ${
                    selectedAnalysis?.id === savedAnalysis.id
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-neutral-200 hover:border-neutral-300 hover:bg-neutral-50'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-neutral-900 mb-1 line-clamp-2">
                        {truncateText(savedAnalysis.assignmentPrompt, 80)}
                      </p>
                      <p className="text-xs text-neutral-500">
                        {formatDate(savedAnalysis.createdAt)}
                      </p>
                    </div>
                    <button
                      onClick={(e) => handleDeleteAnalysis(savedAnalysis.id, e)}
                      className="flex-shrink-0 text-red-500 hover:text-red-700 p-1"
                      title="Delete"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </button>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold text-blue-600">
                      Difficulty: {savedAnalysis.difficulty}/10
                    </span>
                    <span className="text-xs text-neutral-500">•</span>
                    <span className="text-xs text-neutral-600">
                      {savedAnalysis.estimatedTime}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}