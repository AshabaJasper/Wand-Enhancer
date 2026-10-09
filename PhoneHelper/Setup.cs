using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

[assembly: AssemblyTitle("Wand Phone Helper Setup")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

internal static class Setup
{
    private static readonly string Root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "WandPhoneHelper");
    private static readonly string[] Files = { "WandPhoneHelper.exe", "QRCoder.dll", "QRCoder-LICENSE.txt", "build-info.json", "README.md" };
    private static readonly string Menu = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "Wand Phone Helper.lnk");
    private static readonly string Desktop = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "Wand Phone Helper.lnk");
    [STAThread]
    private static int Main(string[] args)
    {
        Application.EnableVisualStyles();
        if (Array.IndexOf(args, "--install-silent") >= 0)
        {
            try { Install(false); Console.WriteLine("Installed: " + Root); return 0; }
            catch (Exception e) { Console.WriteLine("Installation failed: " + e.Message); return 1; }
        }
        if (Array.IndexOf(args, "--uninstall") >= 0 || Array.IndexOf(args, "--uninstall-silent") >= 0)
        {
            if (Array.IndexOf(args, "--uninstall-silent") < 0 && MessageBox.Show("Remove Wand Phone Helper and its shortcuts? Wand, its backups and firewall rules are preserved.", "Remove helper", MessageBoxButtons.YesNo) != DialogResult.Yes) return 0;
            Uninstall(); return 0;
        }
        var form = new Form { Text = "Install Wand Phone Helper", ClientSize = new Size(540, 390), MinimumSize = new Size(555, 430), Font = new Font("Segoe UI", 11), StartPosition = FormStartPosition.CenterScreen };
        var body = new FlowLayoutPanel { Dock = DockStyle.Fill, Padding = new Padding(24), FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true };
        form.Controls.Add(body);
        body.Controls.Add(new Label { Text = "Wand Phone Helper", Font = new Font("Segoe UI", 22, FontStyle.Bold), AutoSize = true });
        body.Controls.Add(new Label { Text = "Phone link, offline QR code, local-only firewall repair and public video-guide search.\n\nInstalls for your Windows account. Does not patch Wand or change your subscription.", AutoSize = true, MaximumSize = new Size(460, 0), Margin = new Padding(0, 12, 0, 12) });
        body.Controls.Add(new TextBox { Text = Root, ReadOnly = true, Width = 460, AccessibleName = "Installation folder" });
        var desktop = new CheckBox { Text = "Add a desktop shortcut", Checked = true, AutoSize = true }; body.Controls.Add(desktop);
        var status = new Label { AutoSize = true, MaximumSize = new Size(460, 0) }; body.Controls.Add(status);
        var install = new Button { Text = "Install helper", MinimumSize = new Size(180, 44), AutoSize = true }; body.Controls.Add(install);
        install.Click += delegate
        {
            install.Enabled = false;
            try { Install(desktop.Checked); status.Text = "Installed. Find Wand Phone Helper in Start."; Process.Start(new ProcessStartInfo(Path.Combine(Root, "WandPhoneHelper.exe")) { UseShellExecute = true }); form.Close(); }
            catch (Exception e) { status.Text = "Installation failed: " + e.Message; status.ForeColor = Color.Firebrick; install.Enabled = true; }
        };
        Application.Run(form); return 0;
    }
    private static byte[] Resource(string name)
    {
        using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
        using (var memory = new MemoryStream()) { if (stream == null) throw new InvalidDataException("Missing installer file: " + name); stream.CopyTo(memory); return memory.ToArray(); }
    }
    private static string Hash(byte[] data) { using (var sha = SHA256.Create()) return BitConverter.ToString(sha.ComputeHash(data)); }
    private static void Install(bool desktop)
    {
        bool acquired;
        using (var installLock = new System.Threading.Mutex(true, "Local\\WandPhoneHelper-Install-" + System.Security.Principal.WindowsIdentity.GetCurrent().User.Value, out acquired))
        {
        if (!acquired) throw new IOException("Another helper installation is running.");
        Directory.CreateDirectory(Root);
        if ((File.GetAttributes(Root) & FileAttributes.ReparsePoint) != 0)
            throw new IOException("Installation folder is a link. Choose a normal per-user Programs folder.");
        bool existing = false;
        foreach (string name in Files) if (File.Exists(Path.Combine(Root, name))) existing = true;
        if (existing && (!File.Exists(Path.Combine(Root, "build-info.json")) || !File.ReadAllText(Path.Combine(Root, "build-info.json")).Contains("Wand Phone Helper only")))
            throw new IOException("This folder contains files that are not a recognized helper installation. They will not be overwritten.");
        // Stage and verify all bundled files before replacing any installed file.
        foreach (string name in Files)
        {
            byte[] data = Resource(name); string staged = Path.Combine(Root, name + ".new");
            File.WriteAllBytes(staged, data);
            if (Hash(File.ReadAllBytes(staged)) != Hash(data)) throw new IOException("Staged file verification failed: " + name);
        }
        var originalFiles = new System.Collections.Generic.HashSet<string>();
        foreach (string name in Files)
        {
            string target = Path.Combine(Root, name);
            if (File.Exists(target)) { originalFiles.Add(name); File.Copy(target, target + ".previous", true); }
        }
        try
        {
            foreach (string name in Files) File.Copy(Path.Combine(Root, name + ".new"), Path.Combine(Root, name), true);
            foreach (string name in Files) if (Hash(File.ReadAllBytes(Path.Combine(Root, name))) != Hash(Resource(name))) throw new IOException("Installed file verification failed: " + name);
        }
        catch
        {
            foreach (string name in Files)
            {
                string prior = Path.Combine(Root, name + ".previous");
                if (originalFiles.Contains(name)) File.Copy(prior, Path.Combine(Root, name), true);
                else File.Delete(Path.Combine(Root, name));
            }
            throw;
        }
        foreach (string name in Files) { File.Delete(Path.Combine(Root, name + ".new")); File.Delete(Path.Combine(Root, name + ".previous")); }
        File.Copy(Assembly.GetExecutingAssembly().Location, Path.Combine(Root, "Uninstall.exe"), true);
        Shortcut(Menu);
        if (desktop) Shortcut(Desktop);
        var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\WandPhoneHelper");
        using (key) { key.SetValue("DisplayName", "Wand Phone Helper"); key.SetValue("DisplayVersion", "1.0.0"); key.SetValue("Publisher", "AshabaJasper"); key.SetValue("InstallLocation", Root); key.SetValue("UninstallString", "\"" + Path.Combine(Root, "Uninstall.exe") + "\" --uninstall"); key.SetValue("NoModify", 1); key.SetValue("NoRepair", 1); }
        installLock.ReleaseMutex();
        }
    }
    private static void Shortcut(string location)
    {
        var shell = Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell"));
        var link = shell.GetType().InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, shell, new object[] { location });
        if (File.Exists(location))
        {
            string previous = Convert.ToString(link.GetType().InvokeMember("TargetPath", BindingFlags.GetProperty, null, link, new object[0]));
            if (!string.Equals(previous, Path.Combine(Root, "WandPhoneHelper.exe"), StringComparison.OrdinalIgnoreCase))
                throw new IOException("An unrelated shortcut already uses this name: " + location);
        }
        link.GetType().InvokeMember("TargetPath", BindingFlags.SetProperty, null, link, new object[] { Path.Combine(Root, "WandPhoneHelper.exe") });
        link.GetType().InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, link, new object[] { Root });
        link.GetType().InvokeMember("Save", BindingFlags.InvokeMethod, null, link, new object[0]);
        System.Runtime.InteropServices.Marshal.FinalReleaseComObject(link); System.Runtime.InteropServices.Marshal.FinalReleaseComObject(shell);
    }
    private static string Quote(string value) { return "'" + value.Replace("'", "''") + "'"; }
    private static void Uninstall()
    {
        // Only the exact per-user folder and our named files. No recursive delete.
        string script = "$ErrorActionPreference='Stop'; Wait-Process -Id " + Process.GetCurrentProcess().Id + " -ErrorAction SilentlyContinue; $root=" + Quote(Root) + "; $expected=Join-Path $env:LOCALAPPDATA 'Programs\\WandPhoneHelper'; if([IO.Path]::GetFullPath($root) -ne [IO.Path]::GetFullPath($expected)){throw 'Unexpected uninstall folder'}; ";
        foreach (string name in Files) script += "Remove-Item -LiteralPath (Join-Path $root " + Quote(name) + ") -Force -ErrorAction SilentlyContinue; ";
        script += "Remove-Item -LiteralPath (Join-Path $root 'Uninstall.exe') -Force -ErrorAction SilentlyContinue; ";
        foreach (string link in new[] { Menu, Desktop }) script += "if(Test-Path -LiteralPath " + Quote(link) + "){$s=New-Object -ComObject WScript.Shell; $l=$s.CreateShortcut(" + Quote(link) + "); if($l.TargetPath -eq (Join-Path $root 'WandPhoneHelper.exe')){Remove-Item -LiteralPath " + Quote(link) + " -Force}}; ";
        script += "Remove-Item -LiteralPath 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\WandPhoneHelper' -ErrorAction SilentlyContinue; if((Test-Path -LiteralPath $root) -and -not (Get-ChildItem -LiteralPath $root -Force)){Remove-Item -LiteralPath $root};";
        var start = new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe"), "-NoProfile -NonInteractive -EncodedCommand " + Convert.ToBase64String(Encoding.Unicode.GetBytes(script))) { UseShellExecute = false, CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden };
        Process.Start(start);
    }
}
