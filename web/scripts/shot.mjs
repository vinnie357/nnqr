// Headless see-loop harness: launch the running web game, drive it through
// window.NNQR, screenshot each step to .qa/, and print state JSON. This is the
// "Read-on-PNG" loop that works WITHOUT the Playwright MCP server — the agent
// runs this and Reads the emitted PNGs. Candidate seed for a `gameshot` CLI.
//
// Usage: node scripts/shot.mjs [url]
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";

const url = process.argv[2] ?? "http://localhost:1425";
const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 720, height: 580 } });

const log = (label, state) =>
  console.log(`\n[${label}] ${JSON.stringify({
    turn: state.turn,
    currentPlayer: state.currentPlayer,
    selected: state.selected,
    validMoves: state.validMoves,
    pieces: state.pieces.length,
    status: state.status,
    winner: state.winner,
  })}`);

await page.goto(url, { waitUntil: "networkidle" });
await page.waitForFunction("window.NNQR && window.NNQR.getState");

// 1. Initial board.
await page.screenshot({ path: `${outDir}01-initial.png` });
log("initial", await page.evaluate("window.NNQR.getState()"));

// 2. Select a front-row piece — expect a valid-move marker to appear.
const afterSelect = await page.evaluate("window.NNQR.api.select(2, 5)");
await page.screenshot({ path: `${outDir}02-selected.png` });
log("after select(2,5)", afterSelect);

// 3. Move it forward — expect turn to flip to player 2.
const afterMove = await page.evaluate("window.NNQR.api.move(3, 5)");
await page.screenshot({ path: `${outDir}03-moved.png` });
log("after move(3,5)", afterMove);

await browser.close();
console.log(`\nscreenshots written to ${outDir}`);
