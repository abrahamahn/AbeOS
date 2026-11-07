// src/components/StatusCard.tsx
import type { LucideIcon } from "lucide-react";

interface StatusCardProps {
  /** Card title label. */
  title: string;
  /** Primary value to display. */
  value: string;
  /** Optional subtitle or secondary info. */
  subtitle?: string;
  /** Percentage (0-100) for the progress bar. */
  percent?: number;
  /** Lucide icon component. */
  icon?: LucideIcon;
  /** Color variant for the accent. */
  variant?: "cyan" | "green" | "red" | "yellow";
}

const VARIANT_CLASSES = {
  cyan: "text-matrix-cyan",
  green: "text-matrix-green",
  red: "text-matrix-red",
  yellow: "text-matrix-yellow",
} as const;

const BAR_CLASSES = {
  cyan: "bg-matrix-cyan",
  green: "bg-matrix-green",
  red: "bg-matrix-red",
  yellow: "bg-matrix-yellow",
} as const;

const GLOW_SHADOWS = {
  cyan: "0 0 8px -3px rgba(0, 255, 255, 0.12)",
  green: "0 0 8px -3px rgba(0, 255, 65, 0.12)",
  red: "0 0 8px -3px rgba(255, 51, 51, 0.12)",
  yellow: "0 0 8px -3px rgba(255, 255, 0, 0.12)",
} as const;

const HOVER_GLOW_SHADOWS = {
  cyan: "0 0 12px -3px rgba(0, 255, 255, 0.22)",
  green: "0 0 12px -3px rgba(0, 255, 65, 0.22)",
  red: "0 0 12px -3px rgba(255, 51, 51, 0.22)",
  yellow: "0 0 12px -3px rgba(255, 255, 0, 0.22)",
} as const;

const DROP_SHADOW_FILTERS = {
  cyan: "drop-shadow(0 0 2px rgba(0, 255, 255, 0.4))",
  green: "drop-shadow(0 0 2px rgba(0, 255, 65, 0.4))",
  red: "drop-shadow(0 0 2px rgba(255, 51, 51, 0.4))",
  yellow: "drop-shadow(0 0 2px rgba(255, 255, 0, 0.4))",
} as const;

/**
 * Dashboard metric card with glassmorphism, glow borders, and shimmer progress bar.
 *
 * @param props - StatusCard configuration.
 * @returns A styled glass-card metric component.
 */
export function StatusCard({
  title,
  value,
  subtitle,
  percent,
  icon: Icon,
  variant = "cyan",
}: StatusCardProps) {
  return (
    <div
      className="glass-card transition-shadow duration-300"
      style={{ boxShadow: GLOW_SHADOWS[variant], padding: "14px 16px" }}
      onMouseEnter={(e) => {
        e.currentTarget.style.boxShadow = HOVER_GLOW_SHADOWS[variant];
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.boxShadow = GLOW_SHADOWS[variant];
      }}
    >
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
        <span className="text-xs font-medium text-matrix-text-dim">
          {title}
        </span>
        {Icon ? (
          <Icon
            size={16}
            className={VARIANT_CLASSES[variant]}
            style={{ filter: DROP_SHADOW_FILTERS[variant] }}
          />
        ) : null}
      </div>

      <p
        className={`truncate text-sm font-bold ${VARIANT_CLASSES[variant]}`}
        style={{ textShadow: "0 0 4px currentColor", lineHeight: 1.3 }}
        title={value}
      >
        {value}
      </p>

      {subtitle ? (
        <p className="text-xs text-matrix-text-dim" style={{ marginTop: 6 }}>{subtitle}</p>
      ) : null}

      {percent !== undefined ? (
        <div className="h-1.5 overflow-hidden rounded-full bg-matrix-border" style={{ marginTop: 10 }}>
          <div
            className={`shimmer-bar h-full rounded-full transition-all duration-500 ${BAR_CLASSES[variant]}`}
            style={{ width: `${Math.min(percent, 100)}%` }}
          />
        </div>
      ) : null}
    </div>
  );
}
