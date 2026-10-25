using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace WandEnhancer.Utils
{
    public static class ProcessTerminator
    {
        private const int KillAttempts = 5;
        private const int KillRetryDelayMs = 250;

        public static void TryKillProcess(string processName)
        {
            // The launcher itself runs as Wand.exe; never target our own process.
            int selfId = Process.GetCurrentProcess().Id;
            KillUntilGone(processName, () => Others(Process.GetProcessesByName(processName), selfId));
        }

        // Adapted from upstream PR #359; scope shutdown to this installation,
        // and never interrupt an installer that may be replacing its files.
        public static void TryKillProcessesUnder(string directory)
        {
            int selfId = Process.GetCurrentProcess().Id;
            string prefix = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            KillUntilGone("Wand installation helpers", () => Under(prefix, selfId));
        }

        public static bool HasActiveUpdater(string directory)
        {
            string prefix = Path.GetFullPath(directory).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            var processes = Under(prefix, Process.GetCurrentProcess().Id);
            try
            {
                foreach (var process in processes) if (IsUpdater(process)) return true;
                return false;
            }
            finally { foreach (var process in processes) process.Dispose(); }
        }

        private static bool IsUpdater(Process process)
        {
            try
            {
                return !process.HasExited && (string.Equals(process.ProcessName, "Update", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(process.ProcessName, "squirrel", StringComparison.OrdinalIgnoreCase));
            }
            catch (InvalidOperationException) { return false; }
        }

        private static Process[] Under(string prefix, int selfId)
        {
            var result = new List<Process>();
            foreach (var process in Process.GetProcesses())
            {
                bool selected = false;
                try
                {
                    selected = process.Id != selfId && process.MainModule.FileName.StartsWith(prefix, StringComparison.OrdinalIgnoreCase);
                }
                catch (Exception e) when (e is InvalidOperationException || e is System.ComponentModel.Win32Exception || e is NotSupportedException) { }
                if (selected) result.Add(process); else process.Dispose();
            }
            return result.ToArray();
        }

        private static void KillUntilGone(string target, Func<Process[]> find)
        {

            for (int attempt = 0; attempt < KillAttempts; attempt++)
            {
                var processes = find();
                try
                {
                    if (processes.Length == 0)
                    {
                        return;
                    }

                    // Check the whole set before stopping anything.
                    foreach (var process in processes)
                    {
                        if (IsUpdater(process))
                            throw new InvalidOperationException("Wand is updating (" + process.ProcessName + ", PID " + process.Id + "). Wait for the update to finish, then retry.");
                    }
                    foreach (var process in processes)
                    {
                        try
                        {
                            process.Kill();
                            process.WaitForExit(KillRetryDelayMs);
                        }
                        catch (Exception e) when (e is InvalidOperationException || e is System.ComponentModel.Win32Exception)
                        {
                            // Already exited, or protected: the post-loop check decides the outcome.
                        }
                    }
                }
                finally
                {
                    foreach (var process in processes)
                    {
                        process.Dispose();
                    }
                }

                Thread.Sleep(KillRetryDelayMs);
            }

            var survivors = find();
            try
            {
                if (survivors.Length > 0)
                {
                    var names = new List<string>();
                    foreach (var process in survivors) names.Add(process.ProcessName + " (PID " + process.Id + ")");
                    throw new InvalidOperationException($"Failed to close {target}: {string.Join(", ", names)}. Close these processes and retry. An elevated process may require an administrator.");
                }
            }
            finally
            {
                foreach (var process in survivors)
                {
                    process.Dispose();
                }
            }
        }

        private static Process[] Others(Process[] processes, int selfId)
        {
            var result = new List<Process>(processes.Length);
            foreach (var process in processes)
            {
                if (process.Id == selfId)
                {
                    process.Dispose();
                    continue;
                }

                result.Add(process);
            }

            return result.ToArray();
        }
    }
}
