using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using AsarSharp;
using WandEnhancer.Core.Patching.Content;
using WandEnhancer.Core.Patching.Shared;
using WandEnhancer.Core.Patching.Strategies;
using WandEnhancer.Models;
using WandEnhancer.Utils;

namespace WandEnhancer.Core
{
    public class Enhancer
    {
        private const string ResourcesDirectoryName = "resources";
        private const string AppAsarFileName = "app.asar";
        private const string AppAsarUnpackedDirectoryName = "app.asar.unpacked";
        private const string AppAsarBackupFileName = "app.asar.backup";
        private const string AppAsarUnpackedBackupDirectoryName = "app.asar.unpacked.backup";
        private const string IncompletePatchMarkerFileName = ".incomplete-patch";
        private const string ProxyDllFileName = "version.dll";

        private readonly WeModConfig _weModConfig;
        private readonly Action<string, ELogType> _logger;
        private readonly PatchConfig _config;
        private readonly IPatchStrategy _strategy;
        private readonly string _asarPath;
        private readonly string _backupPath;
        private readonly string _unpackedPath;
        private readonly string _unpackedBackupPath;

        /// <summary>For <see cref="Restore"/> requiring install paths but no patch selection.</summary>
        public Enhancer(WeModConfig weModConfig, Action<string, ELogType> logger)
            : this(weModConfig, logger, null)
        {
        }

        public Enhancer(WeModConfig weModConfig, Action<string, ELogType> logger, PatchConfig config)
        {
            _weModConfig = weModConfig;
            _logger = logger;
            _config = config;
            _strategy = config != null ? StrategyFactory.Create(config.Strategy) : null;

            _asarPath = Path.Combine(weModConfig.RootDirectory, ResourcesDirectoryName, AppAsarFileName);
            _unpackedPath = Path.Combine(weModConfig.RootDirectory, ResourcesDirectoryName, AppAsarUnpackedDirectoryName);
            _backupPath = Path.Combine(weModConfig.RootDirectory, ResourcesDirectoryName, AppAsarBackupFileName);
            _unpackedBackupPath = Path.Combine(weModConfig.RootDirectory, ResourcesDirectoryName, AppAsarUnpackedBackupDirectoryName);
        }

        /// <summary>Checks if both backups exist and incomplete marker is absent.</summary>
        public static bool IsPatched(string rootDirectory)
        {
            var resources = Path.Combine(rootDirectory, ResourcesDirectoryName);
            return HasBackup(rootDirectory)
                   && !File.Exists(Path.Combine(resources, IncompletePatchMarkerFileName));
        }

        public static bool HasBackup(string rootDirectory)
        {
            var resources = Path.Combine(rootDirectory, ResourcesDirectoryName);
            return File.Exists(Path.Combine(resources, AppAsarBackupFileName))
                   && Directory.Exists(Path.Combine(resources, AppAsarUnpackedBackupDirectoryName));
        }

        private string SquirrelRoot => LauncherDeployment.SquirrelRootOf(_weModConfig);

        private void SaveAutoPatchConfig()
        {
            string path = Path.Combine(SquirrelRoot, Constants.AutoPatchConfigFileName);
            File.WriteAllText(path, Newtonsoft.Json.JsonConvert.SerializeObject(_config, Newtonsoft.Json.Formatting.Indented));
        }

        private void DeleteAutoPatchConfig()
        {
            string path = Path.Combine(SquirrelRoot, Constants.AutoPatchConfigFileName);
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }

        /// <summary>Reads the patch selection saved next to the launcher, or null on failure.</summary>
        public static PatchConfig LoadAutoPatchConfig(string launcherDirectory)
        {
            try
            {
                string path = Path.Combine(launcherDirectory, Constants.AutoPatchConfigFileName);
                if (!File.Exists(path))
                {
                    return null;
                }

                return Newtonsoft.Json.JsonConvert.DeserializeObject<PatchConfig>(File.ReadAllText(path));
            }
            catch (Exception e) when (e is IOException || e is Newtonsoft.Json.JsonException || e is UnauthorizedAccessException)
            {
                return null;
            }
        }

        public void Patch()
        {
            using (AcquireOperationLock()) PatchCore();
        }

        private FileStream AcquireOperationLock()
        {
            try
            {
                return new FileStream(Path.Combine(_weModConfig.RootDirectory, ".enhancer-operation.lock"),
                    FileMode.OpenOrCreate, FileAccess.ReadWrite, FileShare.None, 1, FileOptions.DeleteOnClose);
            }
            catch (IOException e)
            {
                throw new IOException("Another Enhancer operation may be running. Wait for it to finish before retrying.", e);
            }
        }

        private void PatchCore()
        {
            // A directory left behind by an interrupted restore is not a usable backup.
            // Check the selected source before stopping Wand, replacing files or writing a marker.
            ValidateUnpackedFiles(
                File.Exists(_backupPath) ? _backupPath : _asarPath,
                Directory.Exists(_unpackedBackupPath) ? _unpackedBackupPath : _unpackedPath);
            ProcessTerminator.TryKillProcessesUnder(SquirrelRoot);
            if (_config.Strategy == EPatchStrategy.Static && File.Exists(_weModConfig.ExecutablePath))
                DiskFusePatch.VerifyWritable(_weModConfig.ExecutablePath);
            string markerPath = Path.Combine(Path.GetDirectoryName(_asarPath), IncompletePatchMarkerFileName);
            File.WriteAllText(markerPath, string.Empty);

            // Preparation and replacement can fail too (for example while a game holds a DLL).
            // Keep them inside the same recovery boundary as extraction and patching.
            try
            {
                if (!File.Exists(_backupPath))
                {
                    _logger("[ENHANCER] Creating backup...", ELogType.Info);
                    CreateBackupFile(_asarPath, _backupPath);
                }
                else
                {
                    _logger("[ENHANCER] Backup found, restoring pristine app.asar before patching...", ELogType.Info);
                    AsarSharp.Utils.Extensions.CopyOver(_backupPath, _asarPath);
                }

                if (!Directory.Exists(_unpackedBackupPath) && Directory.Exists(_unpackedPath))
                {
                    _logger("[ENHANCER] Creating backup of app.asar.unpacked...", ELogType.Info);
                    CreateBackupDirectory(_unpackedPath, _unpackedBackupPath);
                }
                else if (Directory.Exists(_unpackedBackupPath))
                {
                    _logger("[ENHANCER] Restoring pristine app.asar.unpacked before patching...", ELogType.Info);
                    ReplaceSupportDirectory(_unpackedBackupPath, _unpackedPath);
                }
                else if (!Directory.Exists(_unpackedPath))
                {
                    throw new Exception("[ENHANCER] app.asar.unpacked is missing and no backup exists. Restore the original Wand installation files or reinstall Wand, then patch again.");
                }

                if (!File.Exists(_asarPath))
                {
                    throw new Exception("app.asar not found");
                }

                // Start from a pristine executable to not inherit a broken signature from prior static patches.
                DiskFusePatch.Remove(_weModConfig.ExecutablePath, _logger);

                ExtractSources();
                new AsarContentPatcher(_unpackedPath, _logger, new JavaScriptPatchApplier(_logger)).Patch(_config.PatchTypes);
                new RemotePanelInjector(_unpackedPath, _logger).Inject(_config.PatchTypes, _config.CustomScriptPaths);
                PackSources();
                _strategy.ApplyEnablement(new PatchContext(_weModConfig, _logger, _unpackedPath));

                // Supervised needs its launcher at every start; static only to re-apply on update.
                if (_strategy.RequiresLauncherAlways || _config.AutoApplyAfterUpdate)
                {
                    LauncherDeployment.Deploy(_weModConfig, _logger);
                    SaveAutoPatchConfig();
                }
                else
                {
                    LauncherDeployment.Restore(_weModConfig);
                    DeleteAutoPatchConfig();
                }

                File.Delete(markerPath);
            }
            catch
            {
                RollbackQuietly();
                throw;
            }

            _logger("[ENHANCER] Done!", ELogType.Success);
        }

        private static void CreateBackupFile(string source, string destination)
        {
            string stagingPath = destination + ".building";
            if (File.Exists(stagingPath))
            {
                File.Delete(stagingPath);
            }

            try
            {
                AsarSharp.Utils.Extensions.CopyOver(source, stagingPath);
                File.Move(stagingPath, destination);
            }
            catch
            {
                if (File.Exists(stagingPath))
                {
                    try
                    {
                        AsarSharp.Utils.Extensions.ClearAttributes(stagingPath);
                        File.Delete(stagingPath);
                    }
                    catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
                    {
                    }
                }

                throw;
            }
        }

        private static void CreateBackupDirectory(string source, string destination)
        {
            string stagingPath = destination + ".building";
            if (Directory.Exists(stagingPath))
            {
                Directory.Delete(stagingPath, true);
            }

            try
            {
                AsarSharp.Utils.Extensions.CopyDirectory(source, stagingPath);
                Directory.Move(stagingPath, destination);
            }
            catch
            {
                if (Directory.Exists(stagingPath))
                {
                    try
                    {
                        Directory.Delete(stagingPath, true);
                    }
                    catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
                    {
                    }
                }

                throw;
            }
        }

        private void ExtractSources()
        {
            try
            {
                _logger("[ENHANCER] Extracting app.asar...", ELogType.Info);
                AsarExtractor.ExtractAll(_asarPath, _unpackedPath);
            }
            catch (Exception e)
            {
                throw new Exception($"[ENHANCER] Failed to unpack app.asar: {e.Message}", e);
            }
        }

        private void PackSources()
        {
            try
            {
                // Extraction must not silently discard native files that the pristine archive needs.
                ValidateUnpackedFiles(_backupPath, _unpackedPath);
                new AsarCreator(_unpackedPath, _asarPath, new CreateOptions
                {
                    Unpack = new Regex(@"^static\\unpacked.*$")
                }).CreatePackageWithOptions();
            }
            catch (Exception e)
            {
                throw new Exception($"[ENHANCER] Failed to pack app.asar: {e.Message}", e);
            }
        }

        private static void ValidateUnpackedFiles(string archivePath, string directory)
        {
            var filesystem = AsarSharp.AsarFileSystem.Disk.ReadFilesystemSync(archivePath);
            foreach (string entryPath in filesystem.ListFiles())
            {
                string relative = entryPath.TrimStart('/', '\\');
                var entry = filesystem.GetFile(relative, followLinks: false);
                if (!entry.IsFile || entry.IsLink || entry.Unpacked != true)
                    continue;

                string path = Path.GetFullPath(Path.Combine(directory, relative));
                if (!AsarSharp.Utils.Extensions.IsPathInside(directory, path))
                    throw new IOException("Invalid unpacked path in the original archive.");

                var file = new FileInfo(path);
                // The vendor signs native binaries after creating the ASAR header;
                // the certificate can make valid on-disk files larger than the recorded size.
                if (!file.Exists || file.Length < entry.Size.Value)
                    throw new IOException(
                        $"The original support files are incomplete: {relative}. " +
                        "Repair Wand and its backup before enhancing. No changes have been applied by this check.");
            }
        }

        /// <summary>Prepare a full replacement before moving the live directory. Never delete it in place.</summary>
        private static void ReplaceSupportDirectory(string source, string destination)
        {
            source = Path.GetFullPath(source);
            destination = Path.GetFullPath(destination);
            if (string.Equals(source, destination, StringComparison.OrdinalIgnoreCase)
                || AsarSharp.Utils.Extensions.IsPathInside(source, destination)
                || AsarSharp.Utils.Extensions.IsPathInside(destination, source))
                throw new IOException("Support backup and live directory must be separate.");

            string staging = destination + ".restore-staging";
            string previous = destination + ".restore-previous";
            // Resume an interrupted directory swap before starting another operation.
            if (Directory.Exists(previous) && !Directory.Exists(destination))
                Directory.Move(previous, destination);
            if (Directory.Exists(previous))
                Directory.Delete(previous, true);
            if (Directory.Exists(staging))
                Directory.Delete(staging, true);

            bool movedOriginal = false;
            try
            {
                AsarSharp.Utils.Extensions.CopyDirectory(source, staging);
                if (Directory.Exists(destination))
                {
                    Directory.Move(destination, previous);
                    movedOriginal = true;
                }
                try { Directory.Move(staging, destination); }
                catch
                {
                    if (movedOriginal && !Directory.Exists(destination))
                        Directory.Move(previous, destination);
                    throw;
                }
            }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException)
            {
                throw new IOException("Could not replace Wand support files safely. " +
                    "Close games and Wand, then retry. The previous files and original backup are retained. " + e.Message, e);
            }
            finally
            {
                // A locked leftover is recoverable on the next attempt; never hide the original error.
                try { if (Directory.Exists(staging)) Directory.Delete(staging, true); }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }
            }
            try { if (Directory.Exists(previous)) Directory.Delete(previous, true); }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }

        public static string GetInstallationIssue(string rootDirectory)
        {
            var resources = Path.Combine(rootDirectory, ResourcesDirectoryName);
            if (File.Exists(Path.Combine(resources, IncompletePatchMarkerFileName)))
                return "A previous change did not finish. Close games, then reapply or restore.";
            try
            {
                ValidateUnpackedFiles(Path.Combine(resources, AppAsarFileName), Path.Combine(resources, AppAsarUnpackedDirectoryName));
                if (HasBackup(rootDirectory))
                    ValidateUnpackedFiles(Path.Combine(resources, AppAsarBackupFileName), Path.Combine(resources, AppAsarUnpackedBackupDirectoryName));
                return null;
            }
            catch (Exception e) { return "Support files need attention: " + e.Message; }
        }

        /// <summary>Best-effort restore after failed patch. Does not throw.</summary>
        private void RollbackQuietly()
        {
            try
            {
                if (File.Exists(_backupPath))
                {
                    AsarSharp.Utils.Extensions.CopyOver(_backupPath, _asarPath);
                }

                if (Directory.Exists(_unpackedBackupPath))
                {
                    ReplaceSupportDirectory(_unpackedBackupPath, _unpackedPath);
                }

                // Undo on-disk fuse and launcher deployment to prevent a tampered unlaunchable Wand.
                LauncherDeployment.Restore(_weModConfig);
                DiskFusePatch.Remove(_weModConfig.ExecutablePath, _logger);

                _logger("[ENHANCER] Patch failed - the original Wand files were restored.", ELogType.Warn);
            }
            catch (Exception e)
            {
                _logger($"[ENHANCER] Patch failed and the rollback did not finish: {e.Message}. " +
                        "Use Restore before launching Wand.", ELogType.Error);
            }
        }

        public void Restore()
        {
            using (AcquireOperationLock()) RestoreCore();
        }

        private void RestoreCore()
        {
            if (!File.Exists(_backupPath) || !Directory.Exists(_unpackedBackupPath))
            {
                throw new Exception("[ENHANCER] Backup is incomplete. Restore the original Wand installation files or reinstall Wand.");
            }

            ProcessTerminator.TryKillProcessesUnder(SquirrelRoot);
            if (File.Exists(_weModConfig.ExecutablePath + ".fusebak"))
                DiskFusePatch.VerifyWritable(_weModConfig.ExecutablePath);
            AsarSharp.Utils.Extensions.CopyOver(_backupPath, _asarPath);

            ReplaceSupportDirectory(_unpackedBackupPath, _unpackedPath);

            // Clean up legacy proxy DLL
            var proxyDllPath = Path.Combine(_weModConfig.RootDirectory, ProxyDllFileName);
            if (File.Exists(proxyDllPath))
            {
                File.Delete(proxyDllPath);
            }

            // Undo all footprints at once: launcher stub and on-disk fuse.
            LauncherDeployment.Restore(_weModConfig);
            DiskFusePatch.Remove(_weModConfig.ExecutablePath, _logger);

            string squirrelRoot = SquirrelRoot;
            foreach (var leftover in new[]
                     {
                         Constants.AutoPatchConfigFileName, LauncherLog.FileName, LauncherLog.PreviousFileName
                     })
            {
                string path = Path.Combine(squirrelRoot, leftover);
                if (File.Exists(path))
                {
                    File.Delete(path);
                }
            }

            string markerPath = Path.Combine(Path.GetDirectoryName(_asarPath), IncompletePatchMarkerFileName);
            if (File.Exists(markerPath))
            {
                File.Delete(markerPath);
            }

            File.Delete(_backupPath);
            Directory.Delete(_unpackedBackupPath, true);
            _logger("[ENHANCER] Backup restored successfully.", ELogType.Success);
        }
    }
}
