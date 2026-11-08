// src/features/maintenance/MaintenancePage.tsx
import { useState, useEffect } from "react";
import { Wrench, Play, Calendar, FileText } from "lucide-react";
import { PageHeader } from "../../components/PageHeader.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { api } from "../../lib/tauri.ts";
import type { ScheduledTask, LogEntry } from "../../lib/types.ts";
import { useScript } from "../../hooks/useScript.ts";
import { SCRIPTS } from "../../lib/constants.ts";

/**
 * Maintenance page: scheduled tasks, audits, logs, and manual triggers.
 */
export function MaintenancePage() {
  const [tasks, setTasks] = useState<ScheduledTask[]>([]);
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const { output, running, execute, clear } = useScript();

  useEffect(() => {
    api.getScheduledTasks().then(setTasks).catch(() => {});
    api.getLogEntries().then(setLogs).catch(() => {});
  }, []);

  return (
    <div>
      <PageHeader
        title="Maintenance"
        description="Scheduled tasks, system audits, and log viewer"
        icon={Wrench}
      />

      {/* Scheduled Tasks */}
      <div className="mb-8">
        <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold text-matrix-text-dim">
          <Calendar size={14} />
          Scheduled Tasks
        </h3>
        {tasks.length > 0 ? (
          <div className="space-y-2">
            {tasks.map((task, i) => (
              <div
                key={i}
                className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-3"
              >
                <span className="text-sm text-matrix-text">{task.name}</span>
                <div className="flex items-center gap-4">
                  <span className="text-xs text-matrix-text-dim">
                    Next: {task.next_run}
                  </span>
                  <span
                    className={`text-xs ${task.status === "Ready" ? "text-matrix-green" : "text-matrix-yellow"}`}
                  >
                    {task.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-xs text-matrix-text-dim">
            No AbeOS scheduled tasks found
          </p>
        )}
      </div>

      {/* Manual Actions */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Run Now
        </h3>
        <div className="flex flex-wrap gap-3">
          <ActionButton
            label="Daily Maintenance"
            script={SCRIPTS.dailyMaintenance}
            running={running}
            execute={execute}
            clear={clear}
          />
          <ActionButton
            label="Health Report"
            script={SCRIPTS.healthReport}
            running={running}
            execute={execute}
            clear={clear}
          />
          <ActionButton
            label="System Audit"
            script={SCRIPTS.systemAudit}
            running={running}
            execute={execute}
            clear={clear}
          />
          <ActionButton
            label="Registry Audit"
            script={SCRIPTS.registryAudit}
            running={running}
            execute={execute}
            clear={clear}
          />
          <ActionButton
            label="Plugin Audit"
            script={SCRIPTS.pluginAudit}
            running={running}
            execute={execute}
            clear={clear}
          />
        </div>
      </div>

      {/* Output */}
      {output.length > 0 ? (
        <div className="mb-8">
          <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
            Output
          </h3>
          <TerminalOutput lines={output} running={running} maxHeight={250} />
        </div>
      ) : null}

      {/* Logs */}
      <div>
        <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold text-matrix-text-dim">
          <FileText size={14} />
          Logs ({logs.length} entries)
        </h3>
        {logs.length > 0 ? (
          <div className="space-y-1">
            {logs.slice(0, 20).map((log, i) => (
              <div
                key={i}
                className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-2"
              >
                <span className="text-xs text-matrix-text">{log.name}</span>
                <div className="flex items-center gap-4">
                  <span className="text-xs text-matrix-text-dim">
                    {log.modified}
                  </span>
                  <span className="text-xs text-matrix-text-dim">
                    {log.size_kb} KB
                  </span>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="text-xs text-matrix-text-dim">No log files found</p>
        )}
      </div>
    </div>
  );
}

function ActionButton({
  label,
  script,
  running,
  execute,
  clear,
}: {
  label: string;
  script: string;
  running: boolean;
  execute: (path: string, args?: string[]) => Promise<number>;
  clear: () => void;
}) {
  return (
    <button
      onClick={() => {
        clear();
        void execute(script);
      }}
      disabled={running}
      className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
    >
      <Play size={14} />
      {label}
    </button>
  );
}
