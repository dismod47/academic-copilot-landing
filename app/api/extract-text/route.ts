import { NextRequest, NextResponse } from 'next/server';
import mammoth from 'mammoth';

// Import pdf-parse v1.1.4 which exports as a function
// @ts-ignore - pdf-parse doesn't have proper TypeScript exports
const pdfParse = require('pdf-parse');

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 }
      );
    }

    const fileName = file.name.toLowerCase();
    const fileBuffer = Buffer.from(await file.arrayBuffer());

    // Validate file size
    if (fileBuffer.length === 0) {
      return NextResponse.json(
        { error: 'The uploaded file is empty.' },
        { status: 400 }
      );
    }

    let extractedText = '';

    if (fileName.endsWith('.pdf')) {
      try {
        // Verify it's actually a PDF by checking the file header
        const pdfHeader = fileBuffer.slice(0, 4).toString();
        if (!pdfHeader.startsWith('%PDF')) {
          console.error('Invalid PDF header:', pdfHeader);
          return NextResponse.json(
            { error: 'Invalid PDF file. The file does not appear to be a valid PDF document.' },
            { status: 400 }
          );
        }

        console.log('[extract-text] Parsing PDF, size:', fileBuffer.length, 'bytes');
        
        // Convert Buffer to Uint8Array if needed for better compatibility
        const pdfData = fileBuffer instanceof Buffer ? fileBuffer : Buffer.from(fileBuffer);
        
        // Parse PDF - pdf-parse accepts Buffer directly
        const data = await pdfParse(pdfData);
        extractedText = data.text || '';
        
        console.log('[extract-text] Extracted text length:', extractedText.length, 'pages:', data.numpages);
      } catch (error: any) {
        console.error('[extract-text] PDF parsing error:', error);
        console.error('[extract-text] Error message:', error?.message);
        console.error('[extract-text] Error stack:', error?.stack);
        
        const errorMessage = error?.message || 'Unknown error';
        return NextResponse.json(
          { error: `Failed to parse PDF file: ${errorMessage}. Please ensure it is a valid PDF and not password-protected.` },
          { status: 400 }
        );
      }
    } else if (fileName.endsWith('.docx')) {
      try {
        const result = await mammoth.extractRawText({ buffer: fileBuffer });
        extractedText = result.value;
      } catch (error) {
        return NextResponse.json(
          { error: 'Failed to parse DOCX file. Please ensure it is a valid DOCX file.' },
          { status: 400 }
        );
      }
    } else if (fileName.endsWith('.txt')) {
      extractedText = fileBuffer.toString('utf-8');
    } else if (fileName.endsWith('.doc')) {
      return NextResponse.json(
        { error: 'Old .doc format is not supported. Please convert your file to .docx format.' },
        { status: 400 }
      );
    } else {
      return NextResponse.json(
        { error: 'Unsupported file type. Please upload PDF, DOCX, or TXT files.' },
        { status: 400 }
      );
    }

    if (!extractedText || extractedText.trim().length === 0) {
      return NextResponse.json(
        { error: 'No text could be extracted from the file. The file may be empty or contain only images.' },
        { status: 400 }
      );
    }

    return NextResponse.json({ text: extractedText });
  } catch (error: any) {
    console.error('[extract-text] Error extracting text:', error);
    console.error('[extract-text] Error message:', error?.message);
    console.error('[extract-text] Error stack:', error?.stack);
    
    const errorMessage = error?.message || 'Unknown error';
    return NextResponse.json(
      { error: `Failed to extract text from file: ${errorMessage}` },
      { status: 500 }
    );
  }
}

