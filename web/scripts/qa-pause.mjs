// QA script: verifies pause overlay behavior and power menu state assertions.
//
// What it checks:
//   1. Start a vs-AI game via the NNQR bridge.
//   2. Press Escape — asserts isPaused() === true.
//   3. Screenshots .qa/pause-01.png (visual confirmation for the lead).
//   4. Press Escape again (or Enter) — asserts isPaused() === false (resumed).
//   5. Screenshots .qa/pause-02-resumed.png.
//   6. Power menu: play until orbs appear, move a piece onto one, select it,
//      print the piece's powers array.

import { chromium } from "playwright";
import { mkdirSync } from "node:fs";

const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 980, height: 620 } });

// ---- Setup ----
await page.goto("http://localhost:1425", { waitUntil: "networkidle" });
await page.waitForFunction("window.NNQR && window.NNQR.api && typeof window.NNQR.isPaused === 'function'");

// Start a vs-AI game.
await page.evaluate("window.NNQR.api.newGame({ mode: 'vsai', difficulty: 'easy' })");
await page.waitForTimeout(300);

// ---- Pause overlay: press Escape (no power targeting active) ----
await page.keyboard.press("Escape");
await page.waitForTimeout(100);

const pausedAfterFirstEscape = await page.evaluate("window.NNQR.isPaused()");
console.log("ASSERT isPaused() after Escape:", pausedAfterFirstEscape, "— expected: true", pausedAfterFirstEscape === true ? "PASS" : "FAIL");

await page.screenshot({ path: `${outDir}pause-01.png` });
console.log("screenshot: .qa/pause-01.png (lead should see dim overlay with Resume + Quit to Title)");

// ---- Resume: press Escape again ----
await page.keyboard.press("Escape");
await page.waitForTimeout(100);

const pausedAfterResume = await page.evaluate("window.NNQR.isPaused()");
console.log("ASSERT isPaused() after second Escape:", pausedAfterResume, "— expected: false", pausedAfterResume === false ? "PASS" : "FAIL");

await page.screenshot({ path: `${outDir}pause-02-resumed.png` });
console.log("screenshot: .qa/pause-02-resumed.png (lead should see normal board, no overlay)");

// ---- Verify board input suspended while paused ----
// Open pause, then try a click on the board — game state should not change.
await page.keyboard.press("Escape"); // open pause
await page.waitForTimeout(100);
const stateBefore = await page.evaluate("JSON.stringify(window.NNQR.getState().turn)");
// Click near the center of the board (should be blocked).
await page.mouse.click(340, 200);
await page.waitForTimeout(100);
const stateAfter = await page.evaluate("JSON.stringify(window.NNQR.getState().turn)");
console.log("ASSERT board input suspended while paused — turn unchanged:",
  stateBefore === stateAfter ? "PASS" : "FAIL",
  `(turn before=${stateBefore}, after=${stateAfter})`);

// Resume before proceeding.
await page.keyboard.press("Escape");
await page.waitForTimeout(100);

// ---- Power menu verification ----
// Play legal hotseat moves until orbs appear (they spawn at turn 7).
await page.evaluate("window.NNQR.api.newGame({ mode: 'hotseat', difficulty: 'easy' })");
await page.waitForTimeout(200);

async function playOne() {
  return page.evaluate(`(() => {
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
for (let i = 0; i < 50 && orbs.length === 0; i++) {
  await playOne();
  await page.waitForTimeout(30);
  orbs = await page.evaluate("window.NNQR.getState().orbs");
}

const st = await page.evaluate("window.NNQR.getState()");
console.log(`\nPower menu verification — turn: ${st.turn}, orbs on board: ${orbs.length}`);

if (orbs.length > 0) {
  const orb = orbs[0];
  console.log("target orb at:", JSON.stringify(orb));

  // Find a piece of the current player adjacent to (or at) the orb.
  const collected = await page.evaluate(`(() => {
    const s = window.NNQR.getState();
    const orb = s.orbs[0];
    if (!orb) return null;
    // Find current player's piece that can move to the orb.
    for (const pc of s.pieces) {
      if (pc.player !== s.currentPlayer) continue;
      const sel = window.NNQR.api.select(pc.row, pc.col);
      const vm = sel.validMoves || [];
      const canReach = vm.find(m => m.row === orb.row && m.col === orb.col);
      if (canReach) {
        const after = window.NNQR.api.move(orb.row, orb.col);
        // Find the moved piece (now at orb location).
        const moved = after.pieces.find(p => p.row === orb.row && p.col === orb.col);
        return moved ? moved.powers : [];
      }
    }
    return null;
  })()`);

  if (collected !== null) {
    console.log("ASSERT piece collected orb — powers:", JSON.stringify(collected));
    console.log("  powers.length > 0:", collected.length > 0 ? "PASS" : "FAIL (orb not collected or piece destroyed by overheat)");

    // Now select that piece and check power menu state.
    const orbPos = orbs[0];
    const pieceWithPowers = await page.evaluate(`(() => {
      const s = window.NNQR.getState();
      const p = s.pieces.find(p => p.row === ${orbPos.row} && p.col === ${orbPos.col});
      return p ? { powers: p.powers } : null;
    })()`);
    console.log("piece at orb location:", JSON.stringify(pieceWithPowers));
  } else {
    console.log("SKIP: no piece could reach the orb this turn");
  }
} else {
  console.log("SKIP: no orbs spawned after 50 moves — cannot test power collection");
}

await browser.close();
console.log(`\nAll screenshots written to ${outDir}`);
