using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using QRCoder;

[assembly: AssemblyTitle("Wand Phone Helper")]
[assembly: AssemblyDescription("Local phone connection setup and public video guide links")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace WandPhoneHelper
{
    internal static class Program
    {
        internal static readonly JavaScriptSerializer Json = new JavaScriptSerializer { MaxJsonLength = 65536 };
        internal static readonly Dictionary<string, object> Contract = ReadContract();
        internal static int Port { get { return Convert.ToInt32(Contract["defaultRemotePort"]); } }
        internal static int Range { get { return Convert.ToInt32(Contract["portScanRange"]); } }
        internal static string BasePath { get { return (string)Contract["basePath"]; } }
        private static Dictionary<string, object> ReadContract()
        {
            using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("web-contract.json"))
            using (var reader = new StreamReader(stream))
                return Json.Deserialize<Dictionary<string, object>>(reader.ReadToEnd());
        }
        [STAThread]
        private static int Main(string[] args)
        {
            if (args.Contains("--self-test")) return SelfTest.Run();
            if (args.Contains("--diagnose"))
            {
                try
                {
                    var found = Discovery.FindAsync().GetAwaiter().GetResult();
                    bool ready = Firewall.IsReadyAsync(found.Endpoints[0]).GetAwaiter().GetResult();
                    Console.WriteLine(Json.Serialize(new { panel = found.Report(), localOnlyFirewallReady = ready }));
                    return 0;
                }
                catch (Exception e) { Console.WriteLine(Json.Serialize(new { ok = false, error = e.Message })); return 1; }
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new HelperWindow());
            return 0;
        }
        internal static string VideoSearch(string game)
        {
            if (string.IsNullOrWhiteSpace(game) || game.Trim().Length > 180) throw new ArgumentException("Enter a game title (up to 180 characters).");
            return "https://www.youtube.com/results?search_query=" + Uri.EscapeDataString(game.Trim() + " gameplay walkthrough guide");
        }
        internal static string QuotePs(string value) { return "'" + value.Replace("'", "''") + "'"; }
        internal static ProcessStartInfo Powershell(string script)
        {
            return new ProcessStartInfo(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe"),
                "-NoProfile -NonInteractive -EncodedCommand " + Convert.ToBase64String(Encoding.Unicode.GetBytes(script)))
                { WindowStyle = ProcessWindowStyle.Hidden, CreateNoWindow = true };
        }
    }
    internal sealed class Endpoint
    {
        internal NetworkInterface Adapter;
        internal IPAddress Address;
        internal int Port;
        internal string Url { get { return "http://" + Address + ":" + Port + Program.BasePath; } }
        internal string RuleName { get { return "WandPhoneHelper-" + Port + "-" + new string(Adapter.Id.Where(c => char.IsLetterOrDigit(c) || c == '-').ToArray()); } }
        public override string ToString() { return Adapter.Name + " · " + Address; }
    }
    internal sealed class Discovery
    {
        internal int Port;
        internal int Games;
        internal List<Endpoint> Endpoints = new List<Endpoint>();
        internal static bool IsPrivate(IPAddress ip)
        {
            if (ip.AddressFamily != AddressFamily.InterNetwork) return false;
            var b = ip.GetAddressBytes();
            return b[0] == 10 || (b[0] == 192 && b[1] == 168) || (b[0] == 172 && b[1] >= 16 && b[1] <= 31);
        }
        internal object Report() { return new { ok = true, port = Port, games = Games, urls = Endpoints.Select(e => e.Url).ToArray() }; }
        internal static async Task<Discovery> FindAsync()
        {
            using (var cancellation = new CancellationTokenSource(6000))
            using (var client = new HttpClient(new HttpClientHandler { UseProxy = false, AllowAutoRedirect = false }))
            {
                var probes = Enumerable.Range(Program.Port, Program.Range + 1).Select(async port =>
                {
                    try
                    {
                        using (var response = await client.GetAsync("http://127.0.0.1:" + port + Program.Contract["healthPath"], cancellation.Token))
                        {
                            if (!response.IsSuccessStatusCode || response.Content.Headers.ContentLength > 65536) return null;
                            var text = await response.Content.ReadAsStringAsync();
                            if (text.Length > 65536) return null;
                            var data = Program.Json.Deserialize<Dictionary<string, object>>(text);
                            if (!data.ContainsKey("ok") || !Equals(data["ok"], true) || !data.ContainsKey("installedAppsCount") || !data.ContainsKey("advertisedUrls")) return null;
                            return new Discovery { Port = port, Games = Convert.ToInt32(data["installedAppsCount"]) };
                        }
                    }
                    catch { return null; }
                }).ToList();
                Discovery found = null;
                while (probes.Count > 0)
                {
                    var completed = await Task.WhenAny(probes); probes.Remove(completed);
                    found = await completed;
                    if (found != null) break;
                }
                cancellation.Cancel(); await Task.WhenAll(probes);
                if (found == null) throw new InvalidOperationException("Wand Remote is not responding. Open Wand, wait for its library, then Refresh.");
                foreach (var nic in NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (nic.OperationalStatus != OperationalStatus.Up || (nic.NetworkInterfaceType != NetworkInterfaceType.Ethernet && nic.NetworkInterfaceType != NetworkInterfaceType.Wireless80211)) continue;
                    var properties = nic.GetIPProperties();
                    if (!properties.GatewayAddresses.Any(g => IsPrivate(g.Address))) continue;
                    foreach (var address in properties.UnicastAddresses.Where(a => IsPrivate(a.Address)))
                        found.Endpoints.Add(new Endpoint { Adapter = nic, Address = address.Address, Port = found.Port });
                }
                if (found.Endpoints.Count == 0) throw new InvalidOperationException("No active local Ethernet or Wi-Fi address found. Connect both devices to the same router, then Refresh.");
                found.Endpoints = found.Endpoints.OrderBy(e => e.Adapter.NetworkInterfaceType == NetworkInterfaceType.Ethernet ? 0 : 1).ToList();
                return found;
            }
        }
    }
    internal static class Firewall
    {
        internal static string MatchScript(Endpoint endpoint)
        {
            string legacy = endpoint.Port == 3223 && endpoint.Adapter.Name == "Ethernet" ? ", 'WandRemote-TCP3223-Ethernet-LocalSubnet'" : "";
            return "$r=Get-NetFirewallRule -Name @(" + Program.QuotePs(endpoint.RuleName) + legacy + ") -ErrorAction SilentlyContinue; $ok=$false; foreach($rule in $r){ $p=$rule|Get-NetFirewallPortFilter; $a=$rule|Get-NetFirewallAddressFilter; $i=$rule|Get-NetFirewallInterfaceFilter; $app=$rule|Get-NetFirewallApplicationFilter; if($rule.Enabled -eq 'True' -and $rule.Direction -eq 'Inbound' -and $rule.Action -eq 'Allow' -and $p.Protocol -eq 'TCP' -and $p.LocalPort -eq '" + endpoint.Port + "' -and @($a.RemoteAddress).Count -eq 1 -and $a.RemoteAddress -eq 'LocalSubnet' -and @($i.InterfaceAlias).Count -eq 1 -and $i.InterfaceAlias -eq " + Program.QuotePs(endpoint.Adapter.Name) + " -and $app.Program -eq 'Any' -and $rule.Profile -eq 'Private, Public'){ $ok=$true } }; if($ok){'ready'}else{'missing'}";
        }
        internal static string RepairScript(Endpoint endpoint)
        {
            return "$ErrorActionPreference='Stop'; $n=" + Program.QuotePs(endpoint.RuleName) + "; if(Get-NetFirewallRule -Name $n -ErrorAction SilentlyContinue){ throw 'Existing helper rule differs; review it in Windows Firewall.' }; New-NetFirewallRule -Name $n -DisplayName 'Wand Phone Helper - local subnet only' -Group 'Wand Phone Helper' -Description 'Phone connection: TCP port and physical interface only; no version-specific executable path.' -Enabled True -Direction Inbound -Action Allow -Protocol TCP -LocalPort " + endpoint.Port + " -RemoteAddress LocalSubnet -InterfaceAlias " + Program.QuotePs(endpoint.Adapter.Name) + " -Profile Private,Public | Out-Null";
        }
        internal static async Task<bool> IsReadyAsync(Endpoint endpoint)
        {
            var start = Program.Powershell(MatchScript(endpoint));
            start.UseShellExecute = false; start.RedirectStandardOutput = true; start.RedirectStandardError = true;
            using (var process = Process.Start(start))
            {
                var output = process.StandardOutput.ReadToEndAsync(); var errors = process.StandardError.ReadToEndAsync();
                if (!await Task.Run(() => process.WaitForExit(15000))) { process.Kill(); throw new TimeoutException("Firewall check timed out. Refresh to retry."); }
                string error = await errors;
                if (process.ExitCode != 0) throw new InvalidOperationException("Windows could not check the firewall. " + error.Trim());
                return (await output).Trim() == "ready";
            }
        }
        internal static async Task RepairAsync(Endpoint endpoint)
        {
            var start = Program.Powershell(RepairScript(endpoint)); start.UseShellExecute = true; start.Verb = "runas";
            using (var process = Process.Start(start))
            {
                if (!await Task.Run(() => process.WaitForExit(60000))) throw new TimeoutException("Administrator prompt has not finished. Complete it, then Refresh.");
                if (process.ExitCode != 0) throw new InvalidOperationException("Windows did not add the rule. Review the rule or retry with administrator approval.");
            }
            if (!await IsReadyAsync(endpoint)) throw new InvalidOperationException("The rule was not verified. Check Windows Firewall.");
        }
    }
    internal sealed class HelperWindow : Form
    {
        private readonly ComboBox networks = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 550 };
        private readonly TextBox address = new TextBox { ReadOnly = true, Width = 550, AccessibleName = "Phone panel address" };
        private readonly Label status = new Label { AutoSize = true, MaximumSize = new Size(550, 0), AccessibleName = "Connection status" };
        private readonly Label firewallStatus = new Label { AutoSize = true, MaximumSize = new Size(550, 0) };
        private readonly PictureBox qr = new PictureBox { Width = 190, Height = 190, SizeMode = PictureBoxSizeMode.Zoom, BackColor = Color.White, AccessibleName = "Scan this QR code on your phone to open Wand Remote" };
        private readonly CheckBox trusted = new CheckBox { Text = "This is my trusted home / private network", AutoSize = true };
        private readonly Button repair = Button("Allow phone on this network");
        private readonly Button refresh = Button("Refresh connection");
        private readonly Button copy = Button("Copy phone link");
        private readonly Button open = Button("Open panel");
        private readonly TextBox game = new TextBox { Width = 550, AccessibleName = "Game title for video guide search" };
        private bool busy, ready;
        private int generation;
        private Endpoint Selected { get { return networks.SelectedItem as Endpoint; } }
        private static Button Button(string text) { return new Button { Text = text, AutoSize = true, MinimumSize = new Size(150, 44) }; }
        internal HelperWindow()
        {
            Text = "Wand Phone Helper · 1.0.0"; Font = new Font("Segoe UI", 11); AutoScaleMode = AutoScaleMode.Dpi;
            ClientSize = new Size(640, 800); MinimumSize = new Size(640, 560); StartPosition = FormStartPosition.CenterScreen;
            var body = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoScroll = true, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(24) }; Controls.Add(body);
            AddText(body, "Connect your phone", 23, FontStyle.Bold);
            AddText(body, "Keep Wand open. Connect both devices to the same router. Ethernet on the PC and Wi-Fi on the phone work together.", 11, FontStyle.Regular);
            body.Controls.Add(refresh); body.Controls.Add(status); body.Controls.Add(networks); body.Controls.Add(address);
            var actions = new FlowLayoutPanel { AutoSize = true }; actions.Controls.Add(copy); actions.Controls.Add(open); body.Controls.Add(actions); body.Controls.Add(qr);
            AddText(body, "If your phone cannot reach this address", 14, FontStyle.Bold);
            AddText(body, "Allow only the panel's TCP port from your local subnet through the selected interface. Windows asks for administrator approval. Antivirus and the network profile stay unchanged.", 10, FontStyle.Regular);
            body.Controls.Add(firewallStatus); body.Controls.Add(trusted); body.Controls.Add(repair);
            AddText(body, "Still blocked? Check guest Wi-Fi / router isolation and phone VPN settings. Use HTTP exactly as shown. 127.0.0.1 refers to the device you type it on. Phone PWA installation still needs trusted HTTPS.", 10, FontStyle.Regular);
            AddText(body, "Gameplay video guides", 17, FontStyle.Bold);
            AddText(body, "Type a game title to open public YouTube search results. This is not a built-in Wand video or AI assistant. Only the title is sent when you click Search.", 10, FontStyle.Regular);
            body.Controls.Add(game); var video = Button("Search video guides"); body.Controls.Add(video);
            var source = new LinkLabel { Text = "Source and instructions", AutoSize = true }; body.Controls.Add(source);
            refresh.Click += async delegate { await RefreshAsync(); };
            networks.SelectedIndexChanged += async delegate { await SelectAsync(); };
            trusted.CheckedChanged += delegate { UpdateButtons(); };
            copy.Click += delegate { try { Clipboard.SetText(address.Text); SetStatus("Phone link copied. Paste it into your phone browser.", false); } catch (Exception e) { SetStatus("Could not copy: " + e.Message + " Select the address and copy manually.", true); } };
            open.Click += delegate { OpenLink(address.Text); };
            video.Click += delegate { try { OpenLink(Program.VideoSearch(game.Text)); } catch (Exception e) { SetStatus(e.Message, true); } };
            source.LinkClicked += delegate { OpenLink("https://github.com/AshabaJasper/Wand-Enhancer/tree/helpers/phone-setup/PhoneHelper"); };
            repair.Click += async delegate
            {
                if (Selected == null || !trusted.Checked || busy) return;
                var endpoint = Selected; busy = true; UpdateButtons(); SetStatus("Waiting for Windows administrator approval…", false);
                try { await Firewall.RepairAsync(endpoint); ready = true; firewallStatus.Text = "Local-only firewall rule verified."; SetStatus("Refresh the link on your phone. A PC check alone cannot prove phone connectivity.", false); }
                catch (Exception e) { SetStatus("Firewall repair did not finish: " + e.Message, true); }
                finally { busy = false; UpdateButtons(); }
            };
            Shown += async delegate { await RefreshAsync(); }; FormClosing += delegate(object sender, FormClosingEventArgs e) { if (busy) e.Cancel = true; }; UpdateButtons();
        }
        private void AddText(Control parent, string text, float size, FontStyle style) { parent.Controls.Add(new Label { Text = text, AutoSize = true, MaximumSize = new Size(550, 0), Font = new Font("Segoe UI", size, style), Margin = new Padding(0, 6, 0, 8) }); }
        private void SetStatus(string text, bool error) { status.Text = text; status.AccessibleDescription = text; status.ForeColor = error ? Color.Firebrick : Color.DarkGreen; AccessibilityNotifyClients(AccessibleEvents.NameChange, -1); }
        private void OpenLink(string url) { try { Process.Start(new ProcessStartInfo(url) { UseShellExecute = true }); } catch (Exception e) { SetStatus("Could not open link: " + e.Message, true); } }
        private void UpdateButtons() { refresh.Enabled = networks.Enabled = !busy; trusted.Enabled = !busy && !ready; repair.Enabled = !busy && !ready && trusted.Checked && Selected != null; copy.Enabled = open.Enabled = !busy && Selected != null; }
        private async Task SelectAsync()
        {
            int selection = ++generation; var endpoint = Selected; ready = false; trusted.Checked = false;
            if (qr.Image != null) { var previous = qr.Image; qr.Image = null; previous.Dispose(); }
            if (endpoint == null) { address.Text = ""; firewallStatus.Text = ""; UpdateButtons(); return; }
            address.Text = endpoint.Url;
            using (var generator = new QRCodeGenerator()) using (var data = generator.CreateQrCode(endpoint.Url, QRCodeGenerator.ECCLevel.Q)) using (var renderer = new QRCode(data)) qr.Image = renderer.GetGraphic(6);
            firewallStatus.Text = "Checking local-only firewall allowance…"; UpdateButtons();
            try { var verified = await Firewall.IsReadyAsync(endpoint); if (selection != generation || IsDisposed) return; ready = verified; firewallStatus.Text = ready ? "Local-only firewall rule active. Open the link on your phone." : "No matching rule verified. If the phone times out, use the repair below."; }
            catch (Exception e) { if (selection == generation && !IsDisposed) firewallStatus.Text = "Firewall status unknown: " + e.Message; }
            UpdateButtons();
        }
        private async Task RefreshAsync()
        {
            if (busy) return; busy = true; UpdateButtons(); networks.Items.Clear(); SetStatus("Checking the running panel and current network…", false);
            try { var found = await Discovery.FindAsync(); networks.Items.AddRange(found.Endpoints.Cast<object>().ToArray()); networks.SelectedIndex = 0; SetStatus("Panel responds on this PC · " + found.Games + " games synced. Scan the QR with your phone.", false); }
            catch (Exception e) { SetStatus(e.Message, true); }
            finally { busy = false; UpdateButtons(); }
        }
    }
    internal static class SelfTest
    {
        private static void Assert(bool condition, string label) { if (!condition) throw new Exception(label); }
        internal static int Run()
        {
            try
            {
                Assert(Discovery.IsPrivate(IPAddress.Parse("192.168.100.166")), "LAN IPv4 accepted");
                Assert(!Discovery.IsPrivate(IPAddress.Loopback) && !Discovery.IsPrivate(IPAddress.Parse("8.8.8.8")) && !Discovery.IsPrivate(IPAddress.Parse("169.254.1.1")), "Loopback, public and link-local excluded");
                Assert(Discovery.IsPrivate(IPAddress.Parse("172.16.0.1")) && !Discovery.IsPrivate(IPAddress.Parse("172.32.0.1")), "172 subnet boundaries");
                Assert(Program.VideoSearch("A & B #1").Contains("A%20%26%20B%20%231"), "Game title safely encoded");
                bool rejected = false; try { Program.VideoSearch(" "); } catch (ArgumentException) { rejected = true; } Assert(rejected, "Empty title rejected");
                Assert(Program.QuotePs("Wi-Fi O'Brien") == "'Wi-Fi O''Brien'", "Interface safely quoted");
                using (var generator = new QRCodeGenerator()) using (var data = generator.CreateQrCode("http://192.168.100.166:3223/remote/", QRCodeGenerator.ECCLevel.Q)) Assert(data.ModuleMatrix.Count > 20, "Offline QR generated");
                var endpoint = new Endpoint { Adapter = NetworkInterface.GetAllNetworkInterfaces().First(), Address = IPAddress.Parse("192.168.1.2"), Port = 3224 };
                string repair = Firewall.RepairScript(endpoint);
                Assert(repair.Contains("-RemoteAddress LocalSubnet") && repair.Contains("-Protocol TCP -LocalPort 3224") && repair.Contains("-InterfaceAlias") && repair.Contains("-Profile Private,Public"), "Firewall repair stays confined to port, interface and LAN");
                Assert(!repair.Contains("Set-NetFirewallProfile") && !repair.Contains("Disable-Net") && !repair.Contains("Remove-NetFirewallRule"), "Repair never disables protection or removes unrelated rules");
                int originalPort = Program.Port, originalRange = Program.Range;
                var closed = new TcpListener(IPAddress.Loopback, 0); closed.Start(); int unusedPort = ((IPEndPoint)closed.LocalEndpoint).Port; closed.Stop();
                bool offlineRejected = false;
                try { Program.Contract["defaultRemotePort"] = unusedPort; Program.Contract["portScanRange"] = 0; Discovery.FindAsync().GetAwaiter().GetResult(); }
                catch (InvalidOperationException) { offlineRejected = true; }
                finally { Program.Contract["defaultRemotePort"] = originalPort; Program.Contract["portScanRange"] = originalRange; }
                Assert(offlineRejected, "Stopped panel produces an honest retry error");
                Console.WriteLine("PASS: 10 helper checks"); return 0;
            }
            catch (Exception e) { Console.WriteLine("FAIL: " + e.Message); return 1; }
        }
    }
}
