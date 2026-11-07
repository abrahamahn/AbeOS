// src/features/dashboard/Dashboard.tsx
import {
  LayoutDashboard,
  Cpu,
  MemoryStick,
  HardDrive,
  Clock,
  Play,
} from "lucide-react";
import { PageHeader } from "../../components/PageHeader.tsx";
import { StatusCard } from "../../components/StatusCard.tsx";
import { MetricChart } from "../../components/MetricChart.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { useSystemHistory } from "../../hooks/useSystemHistory.ts";
import { useScript } from "../../hooks/useScript.ts";
import { SCRIPTS } from "../../lib/constants.ts";

const QUICK_ACTIONS = [
  { label: "Health Report", script: SCRIPTS.healthReport, color: "cyan" },
  { label: "Reset Audio", script: SCRIPTS.resetAudio, color: "green" },
  { label: "Apply Theme", script: SCRIPTS.applyTheme, color: "cyan" },
  { label: "Maintenance", script: SCRIPTS.dailyMaintenance, color: "yellow" },
] as const;

/**
 * Section heading with neon underline treatment matching PageHeader styling.
 *
 * @param props - The label text for the section.
 * @returns A styled section heading with neon accent underline.
 */
function SectionLabel({ children }: { children: string }) {
  return (
    <div className="mb-3">
      <h3 className="text-xs font-semibold text-matrix-text-dim">
        {children}
      </h3>
      <div className="mt-1.5 h-[1px] w-8 bg-gradient-to-r from-matrix-cyan to-transparent" />
    </div>
  );
}

/**
 * Main dashboard showing real-time system metrics, history charts, and quick actions.
 *
 * @returns The dashboard page component.
 */
export function Dashboard() {
  const { current: info, history } = useSystemHistory(3000);
  const { output, running, execute, clear } = useScript();

  const handleQuickAction = (scriptPath: string) => {
    clear();
    void execute(scriptPath);
  };

  const primaryDisk = info?.disks[0];

  const cpuData = history.map((s) => ({ timestamp: s.timestamp, value: s.cpu }));
  const memoryData = history.map((s) => ({
    timestamp: s.timestamp,
    value: s.memory,
  }));

  return (
    <div>
      <PageHeader
        title="Dashboard"
        description="System overview and quick actions"
        icon={LayoutDashboard}
      />

      {/* Metrics Grid */}
      <div className="mb-8 grid grid-cols-4 gap-3">
        <StatusCard
          title="CPU"
          value={info ? `${Math.round(info.cpu_usage)}%` : "--"}
          subtitle={info?.cpu_name ?? "Loading..."}
          percent={info?.cpu_usage}
          icon={Cpu}
          variant="cyan"
        />
        <StatusCard
          title="Memory"
          value={
            info
              ? `${info.memory_used_gb} / ${info.memory_total_gb} GB`
              : "--"
          }
          subtitle={info ? `${info.memory_percent}% used` : undefined}
          percent={info?.memory_percent}
          icon={MemoryStick}
          variant={
            info && info.memory_percent > 85
              ? "red"
              : info && info.memory_percent > 70
                ? "yellow"
                : "green"
          }
        />
        <StatusCard
          title="Disk"
          value={
            primaryDisk
              ? `${primaryDisk.used_gb} / ${primaryDisk.total_gb} GB`
              : "--"
          }
          subtitle={primaryDisk?.mount ?? undefined}
          percent={primaryDisk?.percent}
          icon={HardDrive}
          variant={
            primaryDisk && primaryDisk.percent > 90
              ? "red"
              : primaryDisk && primaryDisk.percent > 75
                ? "yellow"
                : "cyan"
          }
        />
        <StatusCard
          title="Uptime"
          value={info ? `${info.uptime_hours}h` : "--"}
          subtitle={info ? `${info.hostname} • Win ${info.os_version}` : undefined}
          icon={Clock}
          variant="green"
        />
      </div>

      {/* History Charts */}
      <div className="mb-8 grid grid-cols-2 gap-3">
        <MetricChart
          data={cpuData}
          color="var(--color-matrix-cyan)"
          label="CPU"
          height={120}
        />
        <MetricChart
          data={memoryData}
          color="var(--color-matrix-green)"
          label="Memory"
          height={120}
        />
      </div>

      {/* Quick Actions */}
      <div className="mb-8">
        <SectionLabel>Quick Actions</SectionLabel>
        <div className="flex gap-3">
          {QUICK_ACTIONS.map((action) => (
            <button
              key={action.label}
              onClick={() => handleQuickAction(action.script)}
              disabled={running}
              className="group flex items-center gap-2 rounded-md border border-matrix-border bg-matrix-surface px-6 py-3 text-xs text-matrix-text transition-all duration-200 hover:border-matrix-cyan hover:text-matrix-cyan hover:shadow-[0_0_12px_-2px_rgba(0,255,255,0.4)] disabled:opacity-50"
            >
              <Play
                size={12}
                className="transition-[filter] duration-200 group-hover:drop-shadow-[0_0_4px_currentColor]"
              />
              {action.label}
            </button>
          ))}
        </div>
      </div>

      {/* Terminal Output */}
      <div>
        <SectionLabel>Output</SectionLabel>
        <TerminalOutput lines={output} running={running} maxHeight={180} />
      </div>
    </div>
  );
}
