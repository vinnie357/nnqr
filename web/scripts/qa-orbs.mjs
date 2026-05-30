// Validate orb spawning + power menu: play generic legal moves (hotseat) until
// orbs appear (turn 7), screenshot, then collect one and screenshot the menu.
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";

const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 980, height: 620 } });
await p.goto("http://localhost:1425", { waitUntil: "networkidle" });
await p.waitForFunction("window.NNQR && window.NNQR.api");
await p.evaluate("window.NNQR.api.newGame({mode:'hotseat',difficulty:'easy'})");
await p.waitForTimeout(200);

// Play a generic legal move for the current player; returns false if none.
async function playOne() {
  return p.evaluate(`(() => {
    const s = window.NNQR.getState();
    for (const pc of s.pieces) {
      if (pc.player !== s.currentPlayer) continue;
      const sel = window.NNQR.api.select(pc.row, pc.col);
      if (sel.validMoves && sel.validMoves.length) {
        window.NNQR.api.move(sel.validMoves[0].row, sel.validMoves[0].col);
        return true;
      }
    }
    return false;
  })()`);
}

let orbs = [];
for (let i = 0; i < 40 && orbs.length === 0; i++) {
  await playOne();
  await p.waitForTimeout(40);
  orbs = await p.evaluate("window.NNQR.getState().orbs");
}
const st = await p.evaluate("window.NNQR.getState()");
console.log("turn:", st.turn, "orbs:", JSON.stringify(orbs));
await p.screenshot({ path: `${outDir}orbs-01-spawned.png` });

await b.close();
