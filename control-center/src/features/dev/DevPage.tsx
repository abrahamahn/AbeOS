// src/features/dev/DevPage.tsx
import { useState, useEffect } from "react";
import {
  Code,
  RefreshCw,
  Globe,
  Music,
  Brain,
  PackagePlus,
  Play,
  Bot,
  Save,
  RotateCcw,
} from "lucide-react";
import { Command } from "@tauri-apps/plugin-shell";
import { PageHeader } from "../../components/PageHeader.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { useScript } from "../../hooks/useScript.ts";
import { SCRIPTS } from "../../lib/constants.ts";
import type { ScriptOutput } from "../../lib/tauri.ts";
import type { LucideIcon } from "lucide-react";

interface ToolVersion {
  name: string;
  version: string;
  status: "ok" | "missing" | "loading";
}

const TOOL_CHECKS: Array<{ name: string; cmd: string }> = [
  { name: "Node.js", cmd: "node --version" },
  { name: "pnpm", cmd: "pnpm --version" },
  { name: "Bun", cmd: "bun --version" },
  { name: "Python", cmd: "python --version" },
  { name: "Git", cmd: "git --version" },
  { name: "Docker", cmd: "docker --version" },
  { name: "Rust", cmd: "rustc --version" },
  { name: "Go", cmd: "go version" },
  { name: "Java", cmd: "java --version" },
  { name: ".NET", cmd: "dotnet --version" },
  { name: "TypeScript", cmd: "tsc --version" },
  { name: "CMake", cmd: "cmake --version" },
  { name: "GitHub CLI", cmd: "gh --version" },
  { name: "Claude CLI", cmd: "claude --version" },
];

const DEV_CATEGORIES: Array<{
  name: string;
  description: string;
  arg: string;
  icon: LucideIcon;
}> = [
  {
    name: "Web Dev",
    description:
      "Node, pnpm, Bun, Git, Python, Docker, Rust, Go, Java, .NET, VS Code, TypeScript",
    arg: "WebDev",
    icon: Globe,
  },
  {
    name: "VST Plugin Dev",
    description: "VS Build Tools (C++), CMake, JUCE, Rust, Git, Python, VS Code",
    arg: "VSTDev",
    icon: Music,
  },
  {
    name: "ML / DL Dev",
    description: "Python, Miniconda, CUDA Toolkit, Git, VS Code, Jupyter",
    arg: "MLDev",
    icon: Brain,
  },
  {
    name: "AI CLI Tools",
    description:
      "Claude CLI, Codex CLI, Gemini CLI, GitHub CLI + WSL installs",
    arg: "AITools",
    icon: Bot,
  },
  {
    name: "Install All",
    description: "All categories combined, deduplicated",
    arg: "All",
    icon: PackagePlus,
  },
];

/**
 * Development environment page: installer categories, tool versions, WSL status,
 * and settings backup/restore.
 */
export function DevPage() {
  const [tools, setTools] = useState<ToolVersion[]>(
    TOOL_CHECKS.map((t) => ({ name: t.name, version: "", status: "loading" }))
  );
  const [wslOutput, setWslOutput] = useState<ScriptOutput[]>([]);
  const { output, running, execute, clear } = useScript();

  useEffect(() => {
    TOOL_CHECKS.forEach((check, i) => {
      void checkTool(check.cmd).then((version) => {
        setTools((prev) => {
          const next = [...prev];
          next[i] = {
            name: check.name,
            version,
            status: version ? "ok" : "missing",
          };
          return next;
        });
      });
    });

    void checkWsl().then(setWslOutput);
  }, []);

  const refreshTools = () => {
    setTools(
      TOOL_CHECKS.map((t) => ({
        name: t.name,
        version: "",
        status: "loading",
      }))
    );
    TOOL_CHECKS.forEach((check, i) => {
      void checkTool(check.cmd).then((version) => {
        setTools((prev) => {
          const next = [...prev];
          next[i] = {
            name: check.name,
            version,
            status: version ? "ok" : "missing",
          };
          return next;
        });
      });
    });
  };

  const handleInstallCategory = (arg: string) => {
    clear();
    void execute(SCRIPTS.installDevEnv, ["-Category", arg]);
  };

  const handleBackupSettings = () => {
    clear();
    void execute(SCRIPTS.backupDevSettings, ["-Action", "Backup"]);
  };

  const handleRestoreSettings = () => {
    clear();
    void execute(SCRIPTS.backupDevSettings, ["-Action", "Restore"]);
  };

  return (
    <div>
      <PageHeader
        title="Development"
        description="Dev environment setup, tool versions, and WSL status"
        icon={Code}
      />

      {/* Dev Environment Installer */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Environment Installer
        </h3>
        <div className="grid grid-cols-3 gap-3">
          {DEV_CATEGORIES.map((cat) => {
            const Icon = cat.icon;
            return (
              <button
                key={cat.arg}
                onClick={() => handleInstallCategory(cat.arg)}
                disabled={running}
                className="rounded border border-matrix-border bg-matrix-surface p-4 text-left transition-colors hover:border-matrix-cyan disabled:opacity-50"
              >
                <div className="flex items-center gap-2">
                  <Icon size={14} className="text-matrix-cyan" />
                  <span className="text-sm font-semibold text-matrix-text">
                    {cat.name}
                  </span>
                </div>
                <p className="mt-1 text-xs text-matrix-text-dim">
                  {cat.description}
                </p>
              </button>
            );
          })}
        </div>
      </div>

      {/* Settings Backup / Restore */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          IDE Settings
        </h3>
        <div className="flex gap-3">
          <button
            onClick={handleBackupSettings}
            disabled={running}
            className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
          >
            <Save size={14} />
            Backup VS Code + IDE Settings
          </button>
          <button
            onClick={handleRestoreSettings}
            disabled={running}
            className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-yellow hover:text-matrix-yellow disabled:opacity-50"
          >
            <RotateCcw size={14} />
            Restore Settings
          </button>
        </div>
        <p className="mt-2 text-xs text-matrix-text-dim">
          Exports VS Code extensions, settings, keybindings, and AntiGravity
          IDE config to C:\AbeOS\backups\dev-settings\
        </p>
      </div>

      {/* Tool Versions */}
      <div className="mb-8">
        <div className="mb-3 flex items-center justify-between">
          <h3 className="text-sm font-semibold  text-matrix-text-dim">
            Tool Versions
          </h3>
          <button
            onClick={refreshTools}
            className="flex items-center gap-1 text-xs text-matrix-text-dim hover:text-matrix-cyan"
          >
            <RefreshCw size={12} />
            Refresh
          </button>
        </div>
        <div className="grid grid-cols-2 gap-3">
          {tools.map((tool) => (
            <div
              key={tool.name}
              className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-3"
            >
              <span className="text-sm text-matrix-text">{tool.name}</span>
              <span
                className={`text-xs ${
                  tool.status === "ok"
                    ? "text-matrix-green"
                    : tool.status === "missing"
                      ? "text-matrix-red"
                      : "text-matrix-text-dim"
                }`}
              >
                {tool.status === "loading"
                  ? "Checking..."
                  : tool.version || "Not found"}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* WSL Status */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          WSL Distros
        </h3>
        {wslOutput.length > 0 ? (
          <div className="rounded border border-matrix-border bg-matrix-bg p-3 font-mono text-xs">
            {wslOutput.map((line, i) => (
              <div key={i} className="text-matrix-green">
                {line.line}
              </div>
            ))}
          </div>
        ) : (
          <p className="text-xs text-matrix-text-dim">Loading WSL info...</p>
        )}
      </div>

      {/* Run verification */}
      <div className="mb-8">
        <button
          onClick={() => {
            clear();
            void execute(SCRIPTS.installDevEnv, ["-Category", "All"]);
          }}
          disabled={running}
          className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
        >
          <Play size={14} />
          Run Full Detection
        </button>
      </div>

      {output.length > 0 ? (
        <TerminalOutput lines={output} running={running} maxHeight={200} />
      ) : null}
    </div>
  );
}

/**
 * Checks if a CLI tool is available by running its version command.
 *
 * @param cmd - The version command to execute (e.g. "node --version").
 * @returns The version string or empty string if not found.
 */
async function checkTool(cmd: string): Promise<string> {
  try {
    const command = Command.create("powershell", [
      "-NoProfile",
      "-Command",
      cmd,
    ]);
    const result = await command.execute();
    return result.stdout.trim() || result.stderr.trim();
  } catch {
    return "";
  }
}

/**
 * Queries WSL distros via `wsl -l -v`, stripping UTF-16LE null bytes.
 *
 * @returns Array of output lines from WSL.
 */
async function checkWsl(): Promise<ScriptOutput[]> {
  try {
    const command = Command.create("wsl", ["-l", "-v"]);
    const result = await command.execute();
    const cleaned = result.stdout.replace(/\0/g, "");
    return cleaned
      .split("\n")
      .filter((line) => line.trim())
      .map((line) => ({ stream: "stdout" as const, line: line.trim() }));
  } catch {
    return [];
  }
}
