# Your Academic Co-Pilot - Landing Page

A modern, clean landing page for the Academic Co-Pilot app built with Next.js, TypeScript, and Tailwind CSS.

## Getting Started

### Prerequisites

- Node.js (version 18 or higher)
- npm (comes with Node.js)

### Installation

1. **Unzip the project**
   ```bash
   unzip academic-copilot-landing.zip
   cd academic-copilot-landing
   ```

2. **Run the setup script**
   ```bash
   bash setup.sh
   ```
   
   Or, if you prefer:
   ```bash
   ./setup.sh
   ```

   This will install all necessary dependencies.

3. **Start the development server**
   ```bash
   npm run dev
   ```

4. **Open in browser**
   
   Visit [http://localhost:3000](http://localhost:3000) to view the landing page.

## Project Structure

```
academic-copilot-landing/
├── app/
│   ├── layout.tsx       # Root layout component
│   ├── page.tsx         # Home page
│   └── globals.css      # Global styles with Tailwind directives
├── components/
│   ├── Header.tsx       # Top navigation header
│   ├── Hero.tsx         # Hero section with CTA
│   ├── FeatureCard.tsx  # Individual feature card
│   └── FeatureGrid.tsx  # Grid of feature cards
├── package.json         # Dependencies and scripts
├── tsconfig.json        # TypeScript configuration
├── tailwind.config.js   # Tailwind CSS configuration
├── next.config.js       # Next.js configuration
├── setup.sh             # Installation script
└── README.md            # This file
```

## Features

- **Clean, minimal design** with a professional academic aesthetic
- **Fully responsive** layout that works on desktop, tablet, and mobile
- **TypeScript** for type safety
- **Tailwind CSS** for modern, utility-first styling
- **Next.js App Router** for modern React development

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Package Manager**: npm

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## Support

For issues or questions, please refer to the Next.js documentation at [https://nextjs.org/docs](https://nextjs.org/docs).
