// src/components/Layout.tsx
import type { ReactNode } from "react";
import { Sidebar } from "./Sidebar.tsx";
import { TitleBar } from "./TitleBar.tsx";
import { useZoom } from "../hooks/useZoom.ts";

interface LayoutProps {
  children: ReactNode;
}

/**
 * Application shell with custom Win11 titlebar, sidebar navigation, scrollable content area, and zoom support.
 * Ctrl+/- adjusts zoom on the entire UI. Ctrl+0 resets.
 */
export function Layout({ children }: LayoutProps) {
  const { zoom } = useZoom();

  return (
    <div
      className="flex h-screen flex-col bg-matrix-bg"
      style={{ zoom: zoom / 100 }}
    >
      <TitleBar />
      <div className="flex flex-1 overflow-hidden">
        <Sidebar />
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
    </div>
  );
}
