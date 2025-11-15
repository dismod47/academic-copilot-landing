#!/usr/bin/env bash

echo "=========================================="
echo "Installing dependencies for Your Academic Co-Pilot..."
echo "=========================================="
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null
then
    echo "Error: npm is not installed. Please install Node.js and npm first."
    exit 1
fi

# Install dependencies
npm install

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "To start the development server, run:"
echo "  npm run dev"
echo ""
echo "Then visit http://localhost:3000 in your browser."
echo ""
