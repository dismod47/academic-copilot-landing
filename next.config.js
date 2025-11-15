/** @type {import('next').NextConfig} */
const nextConfig = {
  serverExternalPackages: ['pdf-parse'],
  webpack: (config, { isServer }) => {
    if (isServer) {
      // Handle pdfjs-dist and its dependencies
      config.externals = [...(config.externals || []), 'canvas', 'canvas-prebuilt'];
    }
    return config;
  },
}

module.exports = nextConfig
