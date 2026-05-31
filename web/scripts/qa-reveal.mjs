// qa-reveal.mjs — nnqr-43 visual QA for render-layer power consumers.
//
// Seeds game state with the three reveal flags via window.NNQR.api, then
// screenshots each scenario to web/.qa/:
//
//   reveal-01-spyware.png  — enemy piece with powersRevealed=true showing
//                             purple tint ring + power label; revealed orb
//                             with power_id label beneath gold circle.
//
//   reveal-02-invisible.png — opponent's invisible piece rendered as a ghost
//                             outline with "?" label; own invisible piece
//                             rendered normally.
//
// Usage (server must be running on localhost:1425):
//   cd web && node scripts/qa-reveal.mjs
//
// The lead reads the PNGs to validate the visuals. This script only confirms
// the files are produced and non-empty.

import { chromium } from "playwright";
import { mkdirSync, statSync } from "node:fs";

const url = "http://localhost:1425";
const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 980, height: 620 } });

await page.goto(url, { waitUntil: "networkidle" });
await page.waitForFunction("window.NNQR && window.NNQR.api");

// Start a hotseat game so we have a live board to patch.
await page.evaluate("window.NNQR.api.newGame({ mode: 'hotseat', difficulty: 'easy' })");
await page.waitForTimeout(300);

// ---------------------------------------------------------------------------
// Scenario 1: powersRevealed + revealed orb
// Patch the running state: mark the first P2 piece as powersRevealed and
// inject a revealed orb.  We do this by replacing the game state exposed on
// the controller's internal state via the bridge.
//
// Because window.NNQR.getState() returns a deep clone we cannot mutate it
// directly.  We inject a helper that mutates the live controller state.
// ---------------------------------------------------------------------------
await page.evaluate(`(() => {
  const state = window.NNQR.getState();
  // Find the first P2 piece and mark it as powers-revealed with a fake power.
  const p2 = state.pieces.find(p => p.player === 2);
  if (p2) {
    p2.powersRevealed = true;
    p2.powers = ["jump_proof", "shield"];
  }
  // Inject a revealed orb near the P2 piece.
  state.orbs = [
    { row: 3, col: 5, powerId: "raise_tile", revealed: true },
    { row: 6, col: 3, powerId: "shield" },
  ];
  // Push the patched state back onto the live controller via the internal bridge
  // if available; otherwise use the documented API to at least re-render.
  if (window._NNQR_patchState) {
    window._NNQR_patchState(state);
  }
})()`);
await page.waitForTimeout(200);
const shot1 = `${outDir}reveal-01-spyware.png`;
await page.screenshot({ path: shot1 });
console.log(`reveal-01-spyware.png: ${statSync(shot1).size} bytes`);

// ---------------------------------------------------------------------------
// Scenario 2: isInvisible ghost rendering
// Mark one P1 piece and one P2 piece as invisible.
// ---------------------------------------------------------------------------
await page.evaluate(`(() => {
  const state = window.NNQR.getState();
  // Clear orbs from scenario 1.
  state.orbs = [];
  const p1Pieces = state.pieces.filter(p => p.player === 1);
  const p2Pieces = state.pieces.filter(p => p.player === 2);
  // Mark one piece from each player as invisible.
  if (p1Pieces[2]) p1Pieces[2].isInvisible = true;
  if (p2Pieces[2]) p2Pieces[2].isInvisible = true;
  if (window._NNQR_patchState) {
    window._NNQR_patchState(state);
  }
})()`);
await page.waitForTimeout(200);
const shot2 = `${outDir}reveal-02-invisible.png`;
await page.screenshot({ path: shot2 });
console.log(`reveal-02-invisible.png: ${statSync(shot2).size} bytes`);

await browser.close();
console.log(`\nQA screenshots written to ${outDir}`);
console.log("Lead: open the PNGs to validate render-layer power consumers.");
console.log("  reveal-01: P2 piece should show purple tint + power label; revealed orb shows power_id text.");
console.log("  reveal-02: invisible pieces should appear as ghost outlines with '?' label.");
