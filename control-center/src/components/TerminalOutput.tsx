// src/components/TerminalOutput.tsx
import { useEffect, useRef } from "react";
import type { ScriptOutput } from "../lib/types.ts";

interface TerminalOutputProps {
  /** Lines of output to render. */
  lines: ScriptOutput[];
  /** Whether the script is still running. */
  running?: boolean;
  /** Maximum height in pixels. */
  maxHeight?: number;
}

/**
 * Scrollable CRT-style terminal output viewer for script execution results.
 * Features scanline overlay, header bar with status indicator, and auto-scroll.
 *
 * @param props - Terminal output configuration.
 * @returns A CRT-styled terminal output component.
 */
export function TerminalOutput({
  lines,
  running = false,
  maxHeight = 300,
}: TerminalOutputProps) {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
    }
  }, [lines]);

  return (
    <div
      className="overflow-hidden rounded border transition-shadow duration-300"
      style={{
        borderColor: running
          ? "rgba(0, 255, 255, 0.4)"
          : "var(--color-matrix-border)",
        boxShadow: running ? "0 0 10px rgba(0, 255, 255, 0.15)" : "none",
        maxWidth: "100%",
      }}
    >
      {/* Header bar */}
      <div className="flex items-center gap-2 border-b border-matrix-border bg-matrix-surface px-3 py-1.5">
        <span
          className="inline-block h-2 w-2 rounded-full"
          style={{
            backgroundColor: running
              ? "var(--color-matrix-green)"
              : "var(--color-matrix-text-dim)",
            boxShadow: running
              ? "0 0 6px var(--color-matrix-green)"
              : "none",
            animation: running ? "neon-pulse 1.5s ease-in-out infinite" : "none",
          }}
        />
        <span className="text-[10px] font-semibold uppercase tracking-widest text-matrix-text-dim">
          Terminal
        </span>
      </div>

      {/* Terminal content with scanline overlay */}
      <div
        ref={containerRef}
        className="scanline-overlay overflow-y-auto overflow-x-hidden bg-matrix-bg p-3 font-mono text-xs"
        style={{ maxHeight, overflowWrap: "break-word", wordBreak: "break-all" }}
      >
        {lines.length === 0 && !running ? (
          <span className="text-matrix-text-dim">
            No output. Run a script to see results here.
          </span>
        ) : null}

        {lines.map((line, i) => (
          <div
            key={i}
            className={
              line.stream === "stderr"
                ? "text-matrix-red"
                : "text-matrix-green"
            }
          >
            <span className="text-matrix-cyan-dim opacity-50">{">_"} </span>
            {line.line}
          </div>
        ))}

        {running ? (
          <div className="mt-1 text-matrix-cyan">
            <span className="text-matrix-cyan-dim opacity-50">{">_"} </span>
            <span
              className="inline-block"
              style={{ animation: "cursor-blink 1s step-end infinite" }}
            >
              {"█"}
            </span>
          </div>
        ) : null}
      </div>
    </div>
  );
}
