import { describe, expect, it } from "vitest";
import {
  createPauseOverlay,
  handleEscape,
  pause,
  resume,
  togglePause,
} from "./pause-overlay";

describe("createPauseOverlay", () => {
  it("starts unpaused", () => {
    expect(createPauseOverlay().paused).toBe(false);
  });
});

describe("togglePause", () => {
  it("opens overlay when unpaused", () => {
    const s = createPauseOverlay();
    expect(togglePause(s).paused).toBe(true);
  });

  it("closes overlay when already paused", () => {
    const s = { paused: true };
    expect(togglePause(s).paused).toBe(false);
  });

  it("is a pure function — does not mutate input", () => {
    const s = createPauseOverlay();
    togglePause(s);
    expect(s.paused).toBe(false);
  });
});

describe("resume", () => {
  it("unpauses from paused state", () => {
    expect(resume({ paused: true }).paused).toBe(false);
  });

  it("is idempotent when already unpaused", () => {
    expect(resume({ paused: false }).paused).toBe(false);
  });
});

describe("pause", () => {
  it("pauses from unpaused state", () => {
    expect(pause({ paused: false }).paused).toBe(true);
  });

  it("is idempotent when already paused", () => {
    expect(pause({ paused: true }).paused).toBe(true);
  });
});

describe("handleEscape — Escape disambiguation", () => {
  it("cancels power targeting when power mode is active, leaves pause unchanged", () => {
    const s = createPauseOverlay();
    const result = handleEscape(s, /* powerModeActive */ true);
    expect(result.action).toBe("cancelPower");
    // Pause state should be untouched — the caller should NOT call togglePause.
  });

  it("does not toggle pause when power mode is active", () => {
    const s = { paused: false };
    const result = handleEscape(s, true);
    expect(result.action).toBe("cancelPower");
    // Verify callers cannot accidentally see a 'next' on a cancelPower result.
    expect("next" in result).toBe(false);
  });

  it("toggles pause when no power mode is active (closed → open)", () => {
    const s = createPauseOverlay(); // paused: false
    const result = handleEscape(s, false);
    expect(result.action).toBe("togglePause");
    if (result.action === "togglePause") {
      expect(result.next.paused).toBe(true);
    }
  });

  it("toggles pause when no power mode is active (open → closed)", () => {
    const s = { paused: true };
    const result = handleEscape(s, false);
    expect(result.action).toBe("togglePause");
    if (result.action === "togglePause") {
      expect(result.next.paused).toBe(false);
    }
  });

  it("pressing Escape twice (no power mode) restores original state", () => {
    const s = createPauseOverlay();
    const r1 = handleEscape(s, false);
    if (r1.action !== "togglePause") throw new Error("expected togglePause");
    const r2 = handleEscape(r1.next, false);
    if (r2.action !== "togglePause") throw new Error("expected togglePause");
    expect(r2.next.paused).toBe(s.paused);
  });

  it("Escape cancels power, second Escape opens overlay (per AC scenario 3)", () => {
    const s = createPauseOverlay(); // paused: false
    // First Escape — power active
    const r1 = handleEscape(s, true);
    expect(r1.action).toBe("cancelPower");
    // After cancellation, power mode is gone; second Escape toggles pause
    const r2 = handleEscape(s, false);
    expect(r2.action).toBe("togglePause");
    if (r2.action === "togglePause") {
      expect(r2.next.paused).toBe(true);
    }
  });
});
