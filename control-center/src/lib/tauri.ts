// src/lib/tauri.ts
import { invoke } from "@tauri-apps/api/core";
import { Command } from "@tauri-apps/plugin-shell";
import type {
  AudioInfo,
  DnsConfig,
  HardwareHealth,
  LogEntry,
  ScheduledTask,
  ScriptOutput,
  SystemInfo,
  ThemeStatus,
} from "./types.ts";

/** Typed wrappers around Tauri invoke calls. */
export const api = {
  getSystemInfo: () => invoke<SystemInfo>("get_system_info"),
  getPowerMode: () => invoke<string>("get_power_mode"),
  getDnsConfig: () => invoke<DnsConfig>("get_dns_config"),
  getThemeStatus: () => invoke<ThemeStatus>("get_theme_status"),
  getAudioInfo: () => invoke<AudioInfo>("get_audio_info"),
  getScheduledTasks: () => invoke<ScheduledTask[]>("get_scheduled_tasks"),
  getLogEntries: () => invoke<LogEntry[]>("get_log_entries"),
  getHardwareHealth: () => invoke<HardwareHealth>("get_hardware_health"),
};

/**
 * Executes a PowerShell script and streams output line-by-line.
 *
 * @param scriptPath - Absolute path to the .ps1 script
 * @param args - Additional arguments to pass
 * @param onOutput - Callback for each line of output
 * @param elevated - Whether to run with admin elevation
 * @returns A promise that resolves with the exit code
 */
export async function runScript(
  scriptPath: string,
  args: string[] = [],
  onOutput?: (output: ScriptOutput) => void,
  elevated = false
): Promise<number> {
  const psArgs = [
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    scriptPath,
    ...args,
  ];

  const shellCmd = elevated ? "pwsh" : "powershell";
  const command = Command.create(shellCmd, psArgs);

  command.stdout.on("data", (line: string) => {
    onOutput?.({ stream: "stdout", line });
  });

  command.stderr.on("data", (line: string) => {
    onOutput?.({ stream: "stderr", line });
  });

  const child = await command.spawn();
  return new Promise((resolve) => {
    command.on("close", (data) => {
      resolve(data.code ?? 1);
    });
    command.on("error", () => {
      resolve(1);
    });
    // Keep reference to prevent GC
    void child;
  });
}
