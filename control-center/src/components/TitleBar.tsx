// src/components/TitleBar.tsx
import { useEffect, useRef } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";

/**
 * Win11-style custom titlebar with drag region and window controls.
 * Replaces OS decorations (tauri.conf.json: decorations: false).
 *
 * Drag uses a native DOM mousedown listener (not data-tauri-drag-region or React
 * synthetic events) to call startDragging() — this bypasses the IPC bridge on
 * every mousemove that data-tauri-drag-region uses, eliminating stutter on Windows.
 */
export function TitleBar() {
  const win = (() => { try { return getCurrentWindow(); } catch { return null; } })();
  const barRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = barRef.current;
    if (!el) return;
    const onMouseDown = (e: MouseEvent) => {
      if (e.buttons === 1 && !(e.target as HTMLElement).closest("button")) {
        win?.startDragging();
      }
    };
    el.addEventListener("mousedown", onMouseDown);
    return () => el.removeEventListener("mousedown", onMouseDown);
  }, [win]);

  return (
    <div
      ref={barRef}
      className="flex h-8 shrink-0 items-center border-b border-matrix-border bg-matrix-bg"
      style={{ userSelect: "none" }}
    >
      {/* Label — not interactive, drag handled by parent div listener */}
      <span className="flex-1 px-4 text-xs text-matrix-text-dim">
        AbeOS Control Center
      </span>

      {/* Window controls — not part of drag region */}
      <div className="flex h-full">
        <button
          onClick={() => win?.minimize()}
          className="flex h-full w-11 items-center justify-center text-matrix-text-dim transition-colors hover:bg-white/10 hover:text-matrix-text"
          aria-label="Minimize"
        >
          <svg width="10" height="1" viewBox="0 0 10 1" fill="currentColor">
            <rect width="10" height="1" />
          </svg>
        </button>
        <button
          onClick={() => win?.toggleMaximize()}
          className="flex h-full w-11 items-center justify-center text-matrix-text-dim transition-colors hover:bg-white/10 hover:text-matrix-text"
          aria-label="Maximize"
        >
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="1">
            <rect x="0.5" y="0.5" width="9" height="9" />
          </svg>
        </button>
        <button
          onClick={() => win?.close()}
          className="flex h-full w-11 items-center justify-center text-matrix-text-dim transition-colors hover:bg-[rgba(196,43,28,0.9)] hover:text-white"
          aria-label="Close"
        >
          <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round">
            <line x1="0" y1="0" x2="10" y2="10" />
            <line x1="10" y1="0" x2="0" y2="10" />
          </svg>
        </button>
      </div>
    </div>
  );
}
