// src/components/Sidebar.tsx
import { NavLink } from "react-router-dom";

const NAV_ITEMS = [
  { path: "/", label: "Dashboard" },
  { path: "/system", label: "System" },
  { path: "/security", label: "Security" },
  { path: "/theme", label: "Theme" },
  { path: "/dev", label: "Dev" },
  { path: "/audio", label: "Audio" },
  { path: "/maintenance", label: "Maint." },
] as const;

/**
 * Left sidebar with Matrix-themed neon navigation links.
 *
 * @returns The sidebar navigation component with neon glow effects.
 */
export function Sidebar() {
  return (
    <aside className="flex w-44 flex-col border-r border-matrix-border bg-gradient-to-b from-matrix-surface to-matrix-bg">
      {/* Logo */}
      <div className="border-b border-matrix-border px-5 py-5">
        <h1
          className="text-xl font-bold text-matrix-cyan"
          style={{
            textShadow: "0 0 10px currentColor",
            animation: "neon-pulse 3s ease-in-out infinite",
          }}
        >
          AbeOS
        </h1>
        <p className="mt-0.5 text-xs text-matrix-text-dim">Control Center</p>
      </div>

      {/* Nav links */}
      <nav className="flex-1 space-y-1 px-3 py-4">
        {NAV_ITEMS.map((item) => {
          return (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === "/"}
              className={({ isActive }) =>
                [
                  "flex items-center rounded px-3 py-2.5 text-sm transition-all duration-200",
                  isActive
                    ? "border-l-[3px] border-matrix-cyan bg-matrix-surface-light text-matrix-cyan shadow-[inset_0_0_8px_rgba(0,255,255,0.1)]"
                    : "border-l-[3px] border-transparent text-matrix-text-dim hover:bg-matrix-surface-light hover:text-matrix-text",
                ].join(" ")
              }
              style={({ isActive }) =>
                isActive
                  ? { borderLeftColor: "var(--color-matrix-cyan)", boxShadow: "0 0 8px rgba(0,255,255,0.15)" }
                  : undefined
              }
            >
              {item.label}
            </NavLink>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="px-5 py-4">
        <div className="mb-2 h-px bg-gradient-to-r from-transparent via-matrix-cyan/40 to-transparent" />
        <p className="text-xs text-matrix-text-dim">v1.0.0</p>
      </div>
    </aside>
  );
}
