// @ts-check
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig({
  site: 'https://www.loqrs.site',
  output: 'static',
  outDir: './build',
  server: {
    port: 1217,
  }
});
