// src/features/system/SystemPage.tsx
import { useState, useEffect } from "react";
import { Cpu, Zap, Play, RefreshCw } from "lucide-react";
import { PageHeader } from "../../components/PageHeader.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { api } from "../../lib/tauri.ts";
import type { HardwareHealth } from "../../lib/types.ts";
import { useScript } from "../../hooks/useScript.ts";
import { useSystemInfo } from "../../hooks/useSystemInfo.ts";
import { SCRIPTS } from "../../lib/constants.ts";

const POWER_MODES = [
  {
    name: "Silent",
    description: "Low power, quiet fans - battery saving and light tasks",
    arg: "Silent",
  },
  {
    name: "Balanced",
    description: "Adaptive clocks, moderate fans - daily use",
    arg: "Balanced",
  },
  {
    name: "Turbo",
    description: "Max clocks, full fans, full GPU - gaming and heavy builds",
    arg: "Turbo",
  },
] as const;

/**
 * System page: power mode switching, hardware health, and optimization controls.
 */
export function SystemPage() {
  const info = useSystemInfo(5000);
  const [currentPlan, setCurrentPlan] = useState("Loading...");
  const [health, setHealth] = useState<HardwareHealth | null>(null);
  const { output, running, execute, clear } = useScript();

  useEffect(() => {
    api.getPowerMode().then(setCurrentPlan).catch(() => setCurrentPlan("Unknown"));
    api.getHardwareHealth().then(setHealth).catch(() => {});
  }, []);

  const refreshHealth = () => {
    setHealth(null);
    api.getHardwareHealth().then(setHealth).catch(() => {});
  };

  const handleSetPowerMode = (arg: string) => {
    clear();
    void execute(SCRIPTS.setPowerPlan, [arg]).then(() => {
      api.getPowerMode().then(setCurrentPlan).catch(() => {});
    });
  };

  return (
    <div>
      <PageHeader
        title="System"
        description="Power modes, hardware health, and optimization settings"
        icon={Cpu}
      />

      {/* Power Mode Selector */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Power Mode
        </h3>
        <p className="mb-3 text-xs text-matrix-text-dim">
          Current: <span className="text-matrix-cyan">{currentPlan}</span>
        </p>
        <div className="grid grid-cols-3 gap-3">
          {POWER_MODES.map((mode) => {
            const isActive = currentPlan
              .toLowerCase()
              .includes(mode.name.toLowerCase());
            return (
              <button
                key={mode.name}
                onClick={() => handleSetPowerMode(mode.arg)}
                disabled={running}
                className={`rounded border p-4 text-left transition-colors ${
                  isActive
                    ? "border-matrix-cyan bg-matrix-surface-light text-matrix-cyan"
                    : "border-matrix-border bg-matrix-surface text-matrix-text hover:border-matrix-cyan-dim"
                } disabled:opacity-50`}
              >
                <div className="flex items-center gap-2">
                  <Zap size={14} />
                  <span className="font-semibold">{mode.name}</span>
                </div>
                <p className="mt-1 text-xs text-matrix-text-dim">
                  {mode.description}
                </p>
              </button>
            );
          })}
        </div>
      </div>

      {/* Hardware Overview */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Hardware
        </h3>
        <div className="grid grid-cols-2 gap-3">
          <InfoRow
            label="CPU"
            value={info ? `${info.cpu_name} (${info.cpu_cores} cores)` : "--"}
          />
          <InfoRow
            label="Memory"
            value={info ? `${info.memory_total_gb} GB total` : "--"}
          />
          <InfoRow
            label="OS"
            value={info ? `Windows ${info.os_version}` : "--"}
          />
          <InfoRow
            label="Hostname"
            value={info?.hostname ?? "--"}
          />
        </div>
      </div>

      {/* GPU */}
      {health?.gpu && health.gpu.length > 0 ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            GPU
          </h3>
          <div className="grid grid-cols-2 gap-3">
            {health.gpu.map((gpu, i) => (
              <InfoRow
                key={i}
                label={gpu.name}
                value={`${gpu.vram_gb} GB VRAM - Driver ${gpu.driver_version}`}
                status={gpu.status === "OK" ? "green" : "yellow"}
              />
            ))}
          </div>
        </div>
      ) : null}

      {/* Battery */}
      {health?.battery ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            Battery
          </h3>
          <div className="grid grid-cols-2 gap-3">
            <InfoRow
              label="Health"
              value={`${health.battery.health_percent}%`}
              status={health.battery.health_percent > 80 ? "green" : health.battery.health_percent > 50 ? "yellow" : "red"}
            />
            <InfoRow
              label="Cycle Count"
              value={`${health.battery.cycle_count} cycles`}
            />
            <InfoRow
              label="Charge"
              value={`${health.battery.current_charge_percent}% - ${health.battery.status}`}
            />
            <InfoRow
              label="Capacity"
              value={`${health.battery.full_charge_capacity_mwh} / ${health.battery.design_capacity_mwh} mWh`}
            />
          </div>
        </div>
      ) : null}

      {/* Network */}
      {health?.network_adapters && health.network_adapters.length > 0 ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            Network
          </h3>
          {health.wifi ? (
            <div className="mb-3 flex items-center gap-4 rounded border border-matrix-border bg-matrix-surface px-4 py-3">
              <span className="text-xs text-matrix-text-dim">WiFi</span>
              <span className="text-sm text-matrix-cyan">{health.wifi.ssid}</span>
              <span className="text-xs text-matrix-text-dim">Signal: {health.wifi.signal_percent}%</span>
              <span className="text-xs text-matrix-text-dim">{health.wifi.link_speed}</span>
              <span className="text-xs text-matrix-text-dim">{health.wifi.auth_type}</span>
            </div>
          ) : null}
          <div className="space-y-2">
            {health.network_adapters.map((adapter, i) => (
              <div
                key={i}
                className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-3"
              >
                <div className="flex items-center gap-3">
                  <span className="text-sm text-matrix-text">{adapter.name}</span>
                  <span className="text-xs text-matrix-text-dim">({adapter.adapter_type})</span>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-xs text-matrix-cyan">{adapter.ip_address}</span>
                  <span className="text-xs text-matrix-text-dim">{adapter.link_speed}</span>
                  <span className="text-xs text-matrix-text-dim">{adapter.mac_address}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      {/* Bluetooth */}
      {health?.bluetooth ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            Bluetooth
          </h3>
          <div className="rounded border border-matrix-border bg-matrix-surface px-4 py-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-matrix-text">{health.bluetooth.adapter_name}</span>
              <span className="text-xs text-matrix-green">{health.bluetooth.status}</span>
            </div>
            {health.bluetooth.connected_devices.length > 0 ? (
              <div className="mt-2">
                <span className="text-xs text-matrix-text-dim">Devices: </span>
                <span className="text-xs text-matrix-cyan">
                  {health.bluetooth.connected_devices.join(", ")}
                </span>
              </div>
            ) : null}
          </div>
        </div>
      ) : null}

      {/* Disk Health */}
      {health?.disk_health && health.disk_health.length > 0 ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            Disk Health
          </h3>
          <div className="grid grid-cols-2 gap-3">
            {health.disk_health.map((disk, i) => (
              <InfoRow
                key={i}
                label={`${disk.model} (${disk.media_type})`}
                value={`${disk.size_gb} GB - ${disk.status}${disk.temperature_c !== null ? ` - ${disk.temperature_c}C` : ""}`}
                status={disk.status === "Healthy" ? "green" : disk.status === "Warning" ? "yellow" : "red"}
              />
            ))}
          </div>
        </div>
      ) : null}

      {/* BIOS */}
      {health?.bios ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            BIOS
          </h3>
          <div className="grid grid-cols-3 gap-3">
            <InfoRow label="Version" value={health.bios.version} />
            <InfoRow label="Manufacturer" value={health.bios.manufacturer} />
            <InfoRow label="Release Date" value={health.bios.release_date} />
          </div>
        </div>
      ) : null}

      {/* Disks */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Disk Usage
        </h3>
        <div className="space-y-2">
          {info?.disks.map((disk, i) => (
            <div
              key={i}
              className="flex items-center gap-5 rounded border border-matrix-border bg-matrix-surface p-3"
            >
              <span className="w-20 text-xs text-matrix-text-dim">
                {disk.mount}
              </span>
              <div className="flex-1">
                <div className="h-1.5 overflow-hidden rounded-full bg-matrix-border">
                  <div
                    className={`h-full rounded-full ${disk.percent > 90 ? "bg-matrix-red" : "bg-matrix-cyan"}`}
                    style={{ width: `${disk.percent}%` }}
                  />
                </div>
              </div>
              <span className="text-xs text-matrix-text">
                {disk.used_gb} / {disk.total_gb} GB ({disk.percent}%)
              </span>
            </div>
          )) ?? (
            <p className="text-xs text-matrix-text-dim">Loading...</p>
          )}
        </div>
      </div>

      {/* Actions */}
      <div className="mb-7 flex gap-3">
        <button
          onClick={() => {
            clear();
            void execute(SCRIPTS.systemAudit);
          }}
          disabled={running}
          className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
        >
          <Play size={14} />
          Run System Audit
        </button>
        <button
          onClick={refreshHealth}
          className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan"
        >
          <RefreshCw size={14} />
          Refresh Health
        </button>
      </div>

      {output.length > 0 ? (
        <TerminalOutput lines={output} running={running} maxHeight={200} />
      ) : null}
    </div>
  );
}

/**
 * Displays a labeled info row with optional color-coded status accent.
 *
 * @param props - Label, value, and optional status color.
 * @returns A styled info card.
 */
function InfoRow({
  label,
  value,
  status,
}: {
  label: string;
  value: string;
  status?: "green" | "yellow" | "red";
}) {
  const valueColor = status
    ? { green: "text-matrix-green", yellow: "text-matrix-yellow", red: "text-matrix-red" }[status]
    : "text-matrix-text";

  return (
    <div className="rounded border border-matrix-border bg-matrix-surface px-4 py-3">
      <span className="text-xs text-matrix-text-dim">{label}</span>
      <p className={`text-sm ${valueColor}`}>{value}</p>
    </div>
  );
}
