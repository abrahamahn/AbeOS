// src/features/theme/ThemePage.tsx
import { useState, useEffect } from "react";
import { Palette, CheckCircle, XCircle, Play } from "lucide-react";
import { PageHeader } from "../../components/PageHeader.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { api } from "../../lib/tauri.ts";
import type { ThemeStatus } from "../../lib/types.ts";
import { useScript } from "../../hooks/useScript.ts";
import { SCRIPTS } from "../../lib/constants.ts";

/**
 * Theme page: view and apply AbeOS UI/UX customizations.
 */
export function ThemePage() {
  const [theme, setTheme] = useState<ThemeStatus | null>(null);
  const { output, running, execute, clear } = useScript();

  useEffect(() => {
    api.getThemeStatus().then(setTheme).catch(() => {});
  }, []);

  const handleApplyTheme = (skipFlags: string[] = []) => {
    clear();
    void execute(SCRIPTS.applyTheme, skipFlags).then(() => {
      api.getThemeStatus().then(setTheme).catch(() => {});
    });
  };

  return (
    <div>
      <PageHeader
        title="Theme"
        description="AbeOS Matrix visual identity — registry, terminal, editors, Chrome"
        icon={Palette}
      />

      {/* Current Theme Status */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Current State
        </h3>
        <div className="grid grid-cols-3 gap-3">
          <ThemeToggle label="Dark Mode" active={theme?.dark_mode ?? false} />
          <ThemeToggle
            label="Window Colorization"
            active={theme?.window_colorization ?? false}
          />
          <ThemeToggle
            label="Verbose Boot"
            active={theme?.verbose_boot ?? false}
          />
          <ThemeToggle
            label="Search Hidden"
            active={theme?.search_hidden ?? false}
          />
          <ThemeToggle
            label="Copilot Hidden"
            active={theme?.copilot_hidden ?? false}
          />
          <ThemeToggle
            label="Task View Hidden"
            active={theme?.task_view_hidden ?? false}
          />
          <ThemeToggle
            label="Widgets Hidden"
            active={theme?.widgets_hidden ?? false}
          />
          <ThemeToggle
            label="Game Bar Off"
            active={theme?.game_bar_off ?? false}
          />
          <div className="rounded border border-matrix-border bg-matrix-surface p-4">
            <span className="text-xs text-matrix-text-dim">Cursor Type</span>
            <p className="mt-1 text-sm text-matrix-cyan">
              {theme?.cursor_type ?? "--"}
            </p>
          </div>
        </div>
      </div>

      {/* OEM Branding */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          OEM Branding
        </h3>
        <div className="flex gap-3">
          <div className="rounded border border-matrix-border bg-matrix-surface px-4 py-3">
            <span className="text-xs text-matrix-text-dim">Manufacturer</span>
            <p className="text-sm text-matrix-text">
              {theme?.oem_manufacturer || "Not set"}
            </p>
          </div>
          <div className="rounded border border-matrix-border bg-matrix-surface px-4 py-3">
            <span className="text-xs text-matrix-text-dim">Model</span>
            <p className="text-sm text-matrix-text">
              {theme?.oem_model || "Not set"}
            </p>
          </div>
        </div>
      </div>

      {/* Apply Buttons */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Apply Theme
        </h3>
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => handleApplyTheme()}
            disabled={running}
            className="flex items-center gap-2 rounded border border-matrix-cyan bg-matrix-surface px-4 py-2.5 text-sm text-matrix-cyan transition-colors hover:bg-matrix-surface-light disabled:opacity-50"
          >
            <Play size={14} />
            Apply All
          </button>
          <button
            onClick={() => handleApplyTheme(["-SkipTerminal"])}
            disabled={running}
            className="rounded border border-matrix-border bg-matrix-surface px-4 py-2 text-xs text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
          >
            Skip Terminal
          </button>
          <button
            onClick={() => handleApplyTheme(["-SkipEditors"])}
            disabled={running}
            className="rounded border border-matrix-border bg-matrix-surface px-4 py-2 text-xs text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
          >
            Skip Editors
          </button>
          <button
            onClick={() => handleApplyTheme(["-SkipChrome"])}
            disabled={running}
            className="rounded border border-matrix-border bg-matrix-surface px-4 py-2 text-xs text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
          >
            Skip Chrome
          </button>
          <button
            onClick={() => handleApplyTheme(["-DryRun"])}
            disabled={running}
            className="rounded border border-matrix-border bg-matrix-surface px-4 py-2 text-xs text-matrix-text-dim transition-colors hover:border-matrix-yellow hover:text-matrix-yellow disabled:opacity-50"
          >
            Dry Run
          </button>
        </div>
      </div>

      {output.length > 0 ? (
        <TerminalOutput lines={output} running={running} maxHeight={250} />
      ) : null}
    </div>
  );
}

function ThemeToggle({ label, active }: { label: string; active: boolean }) {
  return (
    <div className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-3">
      <span className="text-xs text-matrix-text">{label}</span>
      {active ? (
        <CheckCircle size={14} className="text-matrix-green" />
      ) : (
        <XCircle size={14} className="text-matrix-red" />
      )}
    </div>
  );
}
