'use client';

import React, { useState, useRef } from 'react';

interface UploadedFile {
  name: string;
  size: number;
}

export default function SyllabusUpload() {
  const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([]);
  const [pastedText, setPastedText] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDragEnter = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    const files = Array.from(e.dataTransfer.files);
    processFiles(files);
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const files = Array.from(e.target.files);
      processFiles(files);
    }
  };

  const processFiles = (files: File[]) => {
    const validFiles = files.filter((file) => {
      const validTypes = [
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'text/plain',
      ];
      return validTypes.includes(file.type) || 
             file.name.endsWith('.pdf') || 
             file.name.endsWith('.doc') || 
             file.name.endsWith('.docx') || 
             file.name.endsWith('.txt');
    });

    const newFiles = validFiles.map((file) => ({
      name: file.name,
      size: file.size,
    }));

    setUploadedFiles((prev) => [...prev, ...newFiles]);
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  const removeFile = (index: number) => {
    setUploadedFiles((prev) => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="bg-white rounded-xl border border-neutral-200 p-8 shadow-sm space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-neutral-900 mb-2">
          Upload your syllabi
        </h2>
        <p className="text-neutral-600">
          Drop your syllabi here, and we'll later turn them into a calendar of deadlines.
        </p>
      </div>

      {/* File Drop Zone */}
      <div
        onDragEnter={handleDragEnter}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
        className={`border-2 border-dashed rounded-xl p-12 text-center cursor-pointer transition-all ${
          isDragging
            ? 'border-blue-400 bg-blue-50'
            : 'border-neutral-300 bg-neutral-50 hover:border-neutral-400 hover:bg-neutral-100'
        }`}
      >
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept=".pdf,.doc,.docx,.txt"
          onChange={handleFileSelect}
          className="hidden"
        />
        <div className="space-y-2">
          <div className="text-4xl">📄</div>
          <p className="text-neutral-700 font-medium">
            Drop files here or click to browse
          </p>
          <p className="text-sm text-neutral-500">
            Supports PDF, DOC, DOCX, TXT
          </p>
        </div>
      </div>

      {/* Uploaded Files List */}
      {uploadedFiles.length > 0 && (
        <div className="space-y-2">
          <h3 className="font-semibold text-neutral-900">Uploaded Files</h3>
          <div className="space-y-2">
            {uploadedFiles.map((file, index) => (
              <div
                key={index}
                className="flex items-center justify-between bg-neutral-50 border border-neutral-200 rounded-lg p-3"
              >
                <div className="flex items-center gap-3">
                  <div className="text-2xl">📄</div>
                  <div>
                    <p className="text-sm font-medium text-neutral-900">
                      {file.name}
                    </p>
                    <p className="text-xs text-neutral-500">
                      {formatFileSize(file.size)}
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => removeFile(index)}
                  className="text-neutral-400 hover:text-red-600 transition-colors"
                >
                  ✕
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Text Area */}
      <div className="space-y-2">
        <h3 className="font-semibold text-neutral-900">Or paste syllabus text</h3>
        <textarea
          value={pastedText}
          onChange={(e) => setPastedText(e.target.value)}
          placeholder="Paste your syllabus text here..."
          className="w-full h-32 px-4 py-3 border border-neutral-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-300 resize-none"
        />
        {pastedText && (
          <p className="text-sm text-neutral-500">
            {pastedText.length} characters
          </p>
        )}
      </div>
    </div>
  );
}
