// src/hooks/useSystemHistory.ts
import { useState, useEffect, useRef, useCallback } from "react";
import { api } from "../lib/tauri.ts";
import type { SystemInfo } from "../lib/tauri.ts";

/** A single point-in-time snapshot of system metrics. */
export interface SystemSnapshot {
  /** Unix timestamp in milliseconds. */
  timestamp: number;
  /** CPU usage percentage (0-100). */
  cpu: number;
  /** Memory usage percentage (0-100). */
  memory: number;
}

interface UseSystemHistoryResult {
  /** The latest system info snapshot, or null if not yet loaded. */
  current: SystemInfo | null;
  /** Ring buffer of historical metric snapshots for charting. */
  history: SystemSnapshot[];
}

const DEFAULT_MAX_SNAPSHOTS = 30;

/**
 * Wraps system info polling and accumulates historical data points for charts.
 * Maintains a ring buffer of the last `maxSnapshots` readings.
 *
 * @param intervalMs - Polling interval in milliseconds (default 3000).
 * @param maxSnapshots - Maximum number of historical snapshots to retain (default 30).
 * @returns The latest system info and an array of historical metric snapshots.
 */
export function useSystemHistory(
  intervalMs = 3000,
  maxSnapshots = DEFAULT_MAX_SNAPSHOTS,
): UseSystemHistoryResult {
  const [current, setCurrent] = useState<SystemInfo | null>(null);
  const [history, setHistory] = useState<SystemSnapshot[]>([]);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchAndRecord = useCallback(async () => {
    try {
      const data = await api.getSystemInfo();
      setCurrent(data);
      setHistory((prev) => {
        const snapshot: SystemSnapshot = {
          timestamp: Date.now(),
          cpu: data.cpu_usage,
          memory: data.memory_percent,
        };
        const next = [...prev, snapshot];
        if (next.length > maxSnapshots) {
          return next.slice(next.length - maxSnapshots);
        }
        return next;
      });
    } catch {
      setCurrent(null);
    }
  }, [maxSnapshots]);

  useEffect(() => {
    const initialTimeout = setTimeout(() => void fetchAndRecord(), 0);
    intervalRef.current = setInterval(() => void fetchAndRecord(), intervalMs);

    return () => {
      clearTimeout(initialTimeout);
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [intervalMs, fetchAndRecord]);

  return { current, history };
}
