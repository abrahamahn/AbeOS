// src/components/MetricChart.tsx
import { AreaChart, Area, XAxis, YAxis, ResponsiveContainer } from "recharts";
import { useId } from "react";

interface MetricChartProps {
  /** Array of data points with timestamp and value. */
  data: { timestamp: number; value: number }[];
  /** CSS color for the chart line and fill (e.g., "var(--color-matrix-cyan)"). */
  color: string;
  /** Chart height in pixels (default 120). */
  height?: number;
  /** Label displayed above the chart. */
  label?: string;
}

/**
 * Recharts area sparkline with gradient fill and matrix theme styling.
 * Wrapped in a glass-card container matching StatusCard appearance.
 *
 * @param props - Chart configuration.
 * @returns A styled area chart component.
 */
export function MetricChart({
  data,
  color,
  height = 120,
  label,
}: MetricChartProps) {
  const gradientId = useId();

  return (
    <div
      className="glass-card p-4"
      style={{ boxShadow: `0 0 12px -3px color-mix(in srgb, ${color} 25%, transparent)` }}
    >
      {label ? (
        <p className="text-xs font-medium text-matrix-text-dim" style={{ margin: "2px 2px 10px" }}>
          {label}
        </p>
      ) : null}
      <ResponsiveContainer width="100%" height={height}>
        <AreaChart
          data={data}
          margin={{ top: 4, right: 4, bottom: 4, left: 4 }}
        >
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={color} stopOpacity={0.3} />
              <stop offset="100%" stopColor={color} stopOpacity={0.02} />
            </linearGradient>
          </defs>
          <XAxis dataKey="timestamp" hide />
          <YAxis domain={[0, 100]} hide />
          <Area
            type="monotone"
            dataKey="value"
            stroke={color}
            strokeWidth={1.5}
            fill={`url(#${CSS.escape(gradientId)})`}
            isAnimationActive={false}
            style={{ filter: `drop-shadow(0 0 4px ${color})` }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
