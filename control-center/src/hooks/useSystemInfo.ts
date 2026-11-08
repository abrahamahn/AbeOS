// src/hooks/useSystemInfo.ts
import { useState, useEffect, useRef } from "react";
import { api } from "../lib/tauri.ts";
import type { SystemInfo } from "../lib/types.ts";

/**
 * Polls system info from the Rust backend at a configurable interval.
 *
 * @param intervalMs - Polling interval in milliseconds (default 3000).
 * @returns The latest system info snapshot, or null if not yet loaded.
 */
export function useSystemInfo(intervalMs = 3000): SystemInfo | null {
  const [info, setInfo] = useState<SystemInfo | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    const fetchInfo = async () => {
      try {
        const data = await api.getSystemInfo();
        setInfo(data);
      } catch {
        // Tauri not available (dev mode in browser) — use mock data
        setInfo(null);
      }
    };

    void fetchInfo();
    intervalRef.current = setInterval(() => void fetchInfo(), intervalMs);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [intervalMs]);

  return info;
}
