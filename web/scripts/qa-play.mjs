// Visual QA of the integrated game: title -> vs-AI -> select -> move -> AI reply.
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";

const url = "http://localhost:1425";
const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 980, height: 620 } });
const slim = (s) => ({ turn: s.turn, currentPlayer: s.currentPlayer, status: s.status, p1: s.pieces.filter((p) => p.player === 1).length, p2: s.pieces.filter((p) => p.player === 2).length });

await page.goto(url, { waitUntil: "networkidle" });
await page.waitForFunction("window.NNQR && window.NNQR.api");
await page.screenshot({ path: `${outDir}play-01-title.png` });

await page.evaluate("window.NNQR.api.newGame({ mode: 'vsai', difficulty: 'medium' })");
await page.waitForTimeout(400);
await page.screenshot({ path: `${outDir}play-02-board.png` });
console.log("board:", JSON.stringify(slim(await page.evaluate("window.NNQR.getState()"))));

await page.evaluate("window.NNQR.api.select(2, 5)");
await page.waitForTimeout(150);
await page.screenshot({ path: `${outDir}play-03-selected.png` });

await page.evaluate("window.NNQR.api.move(3, 5)");
await page.waitForTimeout(900); // AI think-delay is ~450ms
await page.screenshot({ path: `${outDir}play-04-after-ai.png` });
console.log("after move + AI:", JSON.stringify(slim(await page.evaluate("window.NNQR.getState()"))));

await browser.close();
console.log(`screenshots in ${outDir}`);
