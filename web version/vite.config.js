import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: "https://makkahtv.live",
  plugins: [react()],
  build: {
    // Never emit source maps in production — this is what keeps the original
    // (un-minified) source from being reconstructed inside the browser DevTools.
    sourcemap: false,
    // Minify + mangle so the shipped JS is not human-readable.
    minify: true,
    // Increase warning limit slightly and implement manual chunking to avoid very large bundles
    chunkSizeWarningLimit: 800, // KB
    rollupOptions: {
      output: {
        // Split node_modules and large page components into logical chunks
        manualChunks(id) {
          if (!id) return;
          if (id.includes('node_modules')) {
            // React/runtime/grouped vendor chunks
            if (id.includes('react') || id.includes('react-dom') || id.includes('react-router-dom')) {
              return 'vendor-react';
            }
            // UI-related libraries
            if (id.includes('swiper') || id.includes('react-icons') || id.includes('lucide-react')) {
              return 'vendor-ui';
            }
            // Fallback vendor chunk for remaining node_modules
            return 'vendor';
          }

          // Split large pages/components into separate chunks by filename to enable better caching
          if (id.includes('/src/pages/')) {
            if (id.match(/ArticleDetail/i)) return 'page-article';
            if (id.match(/Videos|ProgramEpisodes|PaginatedVideos/i)) return 'page-media';
            return 'page-others';
          }
        }
      }
    }
  }
});
