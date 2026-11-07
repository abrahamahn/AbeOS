// src/features/audio/AudioPage.tsx
import { useState, useEffect } from "react";
import { Music, Play, RefreshCw, CheckCircle, XCircle } from "lucide-react";
import { PageHeader } from "../../components/PageHeader.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { api } from "../../lib/tauri.ts";
import type { AudioInfo } from "../../lib/tauri.ts";
import { useScript } from "../../hooks/useScript.ts";
import { SCRIPTS } from "../../lib/constants.ts";

/**
 * Audio page: devices, VST plugins, service status, and audio routing.
 */
export function AudioPage() {
  const [audio, setAudio] = useState<AudioInfo | null>(null);
  const { output, running, execute, clear } = useScript();

  const refreshAudio = () => {
    api.getAudioInfo().then(setAudio).catch(() => {});
  };

  useEffect(() => {
    refreshAudio();
  }, []);

  return (
    <div>
      <PageHeader
        title="Audio"
        description="Audio devices, VST plugins, and service management"
        icon={Music}
      />

      {/* Status Overview */}
      <div className="mb-8 grid grid-cols-4 gap-3">
        <div className="rounded border border-matrix-border bg-matrix-surface p-4">
          <span className="text-xs text-matrix-text-dim">Audio Service</span>
          <div className="mt-1 flex items-center gap-2">
            {audio?.audio_service_running ? (
              <CheckCircle size={16} className="text-matrix-green" />
            ) : (
              <XCircle size={16} className="text-matrix-red" />
            )}
            <span
              className={`text-sm font-semibold ${audio?.audio_service_running ? "text-matrix-green" : "text-matrix-red"}`}
            >
              {audio?.audio_service_running ? "Running" : "Stopped"}
            </span>
          </div>
        </div>
        <div className="rounded border border-matrix-border bg-matrix-surface p-4">
          <span className="text-xs text-matrix-text-dim">VST2 Plugins</span>
          <p className="mt-1 text-xl font-bold text-matrix-cyan">
            {audio?.vst2_count ?? "--"}
          </p>
        </div>
        <div className="rounded border border-matrix-border bg-matrix-surface p-4">
          <span className="text-xs text-matrix-text-dim">VST3 Plugins</span>
          <p className="mt-1 text-xl font-bold text-matrix-cyan">
            {audio?.vst3_count ?? "--"}
          </p>
        </div>
        <div className="rounded border border-matrix-border bg-matrix-surface p-4">
          <span className="text-xs text-matrix-text-dim">Devices</span>
          <p className="mt-1 text-xl font-bold text-matrix-cyan">
            {audio?.devices.length ?? "--"}
          </p>
        </div>
      </div>

      {/* Audio Devices */}
      <div className="mb-8">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="text-sm font-semibold text-matrix-text-dim">
            Audio Devices
          </h3>
          <button
            onClick={refreshAudio}
            className="flex items-center gap-1 text-xs text-matrix-text-dim hover:text-matrix-cyan"
          >
            <RefreshCw size={12} />
            Refresh
          </button>
        </div>
        <div className="space-y-2">
          {audio?.devices.map((device, i) => (
            <div
              key={i}
              className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-3"
            >
              <div>
                <span className="text-sm text-matrix-text">{device.name}</span>
                <span className="ml-2 text-xs text-matrix-text-dim">
                  ({device.device_type})
                </span>
              </div>
              <span
                className={`text-xs ${device.status === "OK" ? "text-matrix-green" : "text-matrix-yellow"}`}
              >
                {device.status}
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
            void execute(SCRIPTS.resetAudio).then(refreshAudio);
          }}
          disabled={running}
          className="flex items-center gap-2 rounded border border-matrix-cyan bg-matrix-surface px-4 py-2.5 text-sm text-matrix-cyan transition-colors hover:bg-matrix-surface-light disabled:opacity-50"
        >
          <Play size={14} />
          Reset Audio Stack
        </button>
        <button
          onClick={() => {
            clear();
            void execute(SCRIPTS.pluginAudit);
          }}
          disabled={running}
          className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
        >
          <Play size={14} />
          Scan Plugins
        </button>
      </div>

      {output.length > 0 ? (
        <TerminalOutput lines={output} running={running} maxHeight={250} />
      ) : null}
    </div>
  );
}
