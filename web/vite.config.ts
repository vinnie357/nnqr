import { defineConfig } from "vite";

// Strict port so the AI QA loop and (future) Tauri devUrl always target the same URL.
// 1425 (not Vite's 5173 / desknote's 1420) to avoid clashing with other local dev servers.
export default defineConfig({
  server: { port: 1425, strictPort: true },
  test: {
    globals: true,
    environment: "node",
    include: ["src/**/*.test.ts"],
  },
});
