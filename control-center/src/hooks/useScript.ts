// src/hooks/useScript.ts
import { useState, useCallback, useRef } from "react";
import { runScript } from "../lib/tauri.ts";
import type { ScriptOutput } from "../lib/types.ts";

interface UseScriptReturn {
  /** Accumulated output lines from the script. */
  output: ScriptOutput[];
  /** Whether a script is currently running. */
  running: boolean;
  /** Exit code of the last run, or null if not yet completed. */
  exitCode: number | null;
  /** Execute a PowerShell script by path. */
  execute: (
    scriptPath: string,
    args?: string[],
    elevated?: boolean
  ) => Promise<number>;
  /** Clear the output buffer. */
  clear: () => void;
}

/**
 * React hook for executing AbeOS PowerShell scripts with live streaming output.
 *
 * @returns Script execution state and control functions.
 */
export function useScript(): UseScriptReturn {
  const [output, setOutput] = useState<ScriptOutput[]>([]);
  const [running, setRunning] = useState(false);
  const [exitCode, setExitCode] = useState<number | null>(null);
  const outputRef = useRef<ScriptOutput[]>([]);

  const execute = useCallback(
    async (
      scriptPath: string,
      args: string[] = [],
      elevated = false
    ): Promise<number> => {
      setRunning(true);
      setExitCode(null);
      outputRef.current = [];
      setOutput([]);

      const code = await runScript(
        scriptPath,
        args,
        (line) => {
          outputRef.current = [...outputRef.current, line];
          setOutput([...outputRef.current]);
        },
        elevated
      );

      setExitCode(code);
      setRunning(false);
      return code;
    },
    []
  );

  const clear = useCallback(() => {
    outputRef.current = [];
    setOutput([]);
    setExitCode(null);
  }, []);

  return { output, running, exitCode, execute, clear };
}
