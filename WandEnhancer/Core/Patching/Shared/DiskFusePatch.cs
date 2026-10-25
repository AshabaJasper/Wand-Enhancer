using System;
using System.IO;
using System.Threading;

namespace WandEnhancer.Core.Patching.Shared
{
    /// <summary>
    /// Flips the ASAR-integrity state byte on disk and backs up the original to preserve Authenticode restores.
    /// </summary>
    internal static class DiskFusePatch
    {
        private const string FuseBackupSuffix = ".fusebak";

        // Fail before changing resources if the client image is still mapped.
        public static void VerifyWritable(string exePath)
        {
            using (OpenWritable(exePath)) { }
        }

        private static FileStream OpenWritable(string exePath)
        {
            for (int attempt = 0; ; attempt++)
            {
                try { return new FileStream(exePath, FileMode.Open, FileAccess.ReadWrite, FileShare.Read); }
                catch (IOException e) when ((e.HResult & 0xffff) == 32 || (e.HResult & 0xffff) == 33)
                {
                    if (attempt >= 11)
                        throw new IOException("Wand executable is still locked: " + exePath +
                            ". Close Wand, games using its overlay and installation helpers, then retry. Original backups are retained.", e);
                    Thread.Sleep(250);
                }
            }
        }

        public static bool Apply(string exePath, Action<string, ELogType> log)
        {
            long offset = ElectronFuseWire.FindStateFileOffset(exePath);
            if (offset < 0)
            {
                log?.Invoke($"[ENHANCER] No Electron fuse block in {Path.GetFileName(exePath)}; nothing to flip.", ELogType.Warn);
                return false;
            }

            using (var stream = OpenWritable(exePath))
            {
                stream.Position = offset;
                int original = stream.ReadByte();
                if (original == ElectronFuseWire.StateRemoved)
                {
                    return true;
                }

                string backup = exePath + FuseBackupSuffix;
                if (!File.Exists(backup))
                {
                    File.WriteAllBytes(backup, new[] { (byte)original });
                }

                stream.Position = offset;
                stream.WriteByte(ElectronFuseWire.StateRemoved);
            }

            log?.Invoke($"[ENHANCER] ASAR integrity fuse cleared on disk in {Path.GetFileName(exePath)}.", ELogType.Info);
            return true;
        }

        public static void Remove(string exePath, Action<string, ELogType> log)
        {
            string backup = exePath + FuseBackupSuffix;
            if (!File.Exists(backup))
            {
                return;
            }

            long offset = ElectronFuseWire.FindStateFileOffset(exePath);
            if (offset < 0)
            {
                // No fuse block to restore; keep backup.
                log?.Invoke($"[ENHANCER] Could not locate the fuse to restore in {Path.GetFileName(exePath)}; keeping {FuseBackupSuffix}.", ELogType.Warn);
                return;
            }

            byte original = File.ReadAllBytes(backup)[0];
            using (var stream = OpenWritable(exePath))
            {
                stream.Position = offset;
                stream.WriteByte(original);
            }

            log?.Invoke($"[ENHANCER] ASAR integrity fuse restored on disk in {Path.GetFileName(exePath)}.", ELogType.Info);
            File.Delete(backup);
        }
    }
}
