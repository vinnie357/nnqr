// Verify real mouse clicks on the canvas play the game (not just the window.NNQR
// API). Clicks the front-row piece at (row2,col5), then its highlighted target.
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";

const url = "http://localhost:1425";
const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });

// Tile center in page px: MARGIN(40) + (n-1)*TILE(60) + TILE/2(30).
const tile = (row, col) => ({ x: 40 + (col - 1) * 60 + 30, y: 40 + (row - 1) * 60 + 30 });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 720, height: 580 } });
await page.goto(url, { waitUntil: "networkidle" });
await page.waitForFunction("window.NNQR && window.NNQR.getState");

const sel = tile(2, 5);
await page.mouse.click(sel.x, sel.y);
await page.screenshot({ path: `${outDir}click-01-selected.png` });
console.log("after click select:", JSON.stringify((await page.evaluate("window.NNQR.getState()")).selected));

const dst = tile(3, 5);
await page.mouse.click(dst.x, dst.y);
await page.screenshot({ path: `${outDir}click-02-moved.png` });
const s = await page.evaluate("window.NNQR.getState()");
console.log("after click move:", JSON.stringify({ turn: s.turn, currentPlayer: s.currentPlayer }));

await browser.close();
