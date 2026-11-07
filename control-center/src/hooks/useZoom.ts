// src/hooks/useZoom.ts
import { useState, useEffect, useCallback } from "react";

const ZOOM_KEY = "abeos-zoom-level";
const ZOOM_MIN = 70;
const ZOOM_MAX = 150;
const ZOOM_STEP = 10;
const ZOOM_DEFAULT = 100;

/**
 * Manage UI zoom level with Ctrl+/- keyboard shortcuts.
 * Persists the zoom level to localStorage.
 *
 * @returns Current zoom percentage and setter.
 */
export function useZoom() {
  const [zoom, setZoom] = useState(() => {
    const stored = localStorage.getItem(ZOOM_KEY);
    if (stored) {
      const parsed = Number(stored);
      if (!Number.isNaN(parsed) && parsed >= ZOOM_MIN && parsed <= ZOOM_MAX) {
        return parsed;
      }
    }
    return ZOOM_DEFAULT;
  });

  const zoomIn = useCallback(() => {
    setZoom((prev) => {
      const next = Math.min(prev + ZOOM_STEP, ZOOM_MAX);
      localStorage.setItem(ZOOM_KEY, String(next));
      return next;
    });
  }, []);

  const zoomOut = useCallback(() => {
    setZoom((prev) => {
      const next = Math.max(prev - ZOOM_STEP, ZOOM_MIN);
      localStorage.setItem(ZOOM_KEY, String(next));
      return next;
    });
  }, []);

  const zoomReset = useCallback(() => {
    setZoom(ZOOM_DEFAULT);
    localStorage.setItem(ZOOM_KEY, String(ZOOM_DEFAULT));
  }, []);

  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (!e.ctrlKey && !e.metaKey) return;

      if (e.key === "=" || e.key === "+") {
        e.preventDefault();
        zoomIn();
      } else if (e.key === "-") {
        e.preventDefault();
        zoomOut();
      } else if (e.key === "0") {
        e.preventDefault();
        zoomReset();
      }
    }

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [zoomIn, zoomOut, zoomReset]);

  return { zoom, zoomIn, zoomOut, zoomReset };
}
