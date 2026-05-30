// Validate the populated power menu: in hotseat, drive a chosen piece onto an
// orb, then select it and screenshot the menu showing the collected power.
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";

const outDir = new URL("../.qa/", import.meta.url).pathname;
mkdirSync(outDir, { recursive: true });
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 980, height: 620 } });
await p.goto("http://localhost:1425", { waitUntil: "networkidle" });
await p.waitForFunction("window.NNQR && window.NNQR.api");
await p.evaluate("window.NNQR.api.newGame({mode:'hotseat',difficulty:'easy'})");
await p.waitForTimeout(150);

const state = () => p.evaluate("window.NNQR.getState()");
const dist = (a, t) => Math.abs(a.row - t.row) + Math.abs(a.col - t.col);

// Generic legal move for whoever's turn it is, AVOIDING moving `protectId`.
async function genericMoveExcept(protectId) {
  return p.evaluate(`(() => {
    const s = window.NNQR.getState();
    for (const pc of s.pieces) {
      if (pc.player !== s.currentPlayer) continue;
      if (pc.id === ${JSON.stringify(protectId)}) continue;
      const sel = window.NNQR.api.select(pc.row, pc.col);
      if (sel.validMoves && sel.validMoves.length) {
        window.NNQR.api.move(sel.validMoves[0].row, sel.validMoves[0].col);
        return true;
      }
    }
    return false;
  })()`);
}

// Play until orbs spawn.
let s = await state();
for (let i = 0; i < 40 && s.orbs.length === 0; i++) { await genericMoveExcept(null); await p.waitForTimeout(20); s = await state(); }
const orb = s.orbs[0];
console.log("orbs spawned turn", s.turn, "target orb:", JSON.stringify(orb));

// Lock onto the nearest player-1 piece.
let router = s.pieces.filter((x) => x.player === 1).sort((a, c) => dist(a, orb) - dist(c, orb))[0];
let routerId = router.id;
let collected = [];

for (let i = 0; i < 50; i++) {
  s = await state();
  const me = s.pieces.find((x) => x.id === routerId);
  if (!me) break;
  if (me.row === orb.row && me.col === orb.col) { collected = me.powers; break; }
  if (s.currentPlayer === 1) {
    // Step router toward the orb via its best valid move.
    const sel = await p.evaluate(`window.NNQR.api.select(${me.row}, ${me.col})`);
    const moves = sel.validMoves ?? [];
    if (moves.length) {
      const best = moves.slice().sort((a, c) => dist(a, orb) - dist(c, orb))[0];
      await p.evaluate(`window.NNQR.api.move(${best.row}, ${best.col})`);
    } else { await genericMoveExcept(routerId); }
  } else {
    await genericMoveExcept(routerId);
  }
  await p.waitForTimeout(20);
}

// Ensure it is Player 1's turn so the P1 router piece can be selected (its menu renders).
for (let i = 0; i < 4 && (await state()).currentPlayer !== 1; i++) { await genericMoveExcept(routerId); await p.waitForTimeout(20); }

s = await state();
const me = s.pieces.find((x) => x.id === routerId);
console.log("router final:", me ? JSON.stringify({ row: me.row, col: me.col, powers: me.powers, turnPlayer: s.currentPlayer }) : "lost");
if (me && me.powers.length) {
  await p.evaluate(`window.NNQR.api.select(${me.row}, ${me.col})`);
  await p.waitForTimeout(80);
  await p.screenshot({ path: `${outDir}collect-menu.png` });
  console.log("MENU SCREENSHOT written; collected powers:", JSON.stringify(me.powers));
} else {
  console.log("did not collect within budget");
}
await b.close();
