# 📱 Phone play: your second screen

[← Back to the README](../README.md) · [Quick start](QUICK-START.md) · [Respawn guide](RESPAWN-GUIDE.md)

I keep the phone panel for the controls I want within reach while playing. Your PC still runs Wand, the game and the trainer. Your phone is the remote.

## Connect in four steps

1. Apply with **Remote Web Panel** selected, then open Wand on the PC.
2. Put the PC and phone on the same trusted local network. A PC on Ethernet and a phone on the same router's normal Wi-Fi can work together.
3. Use **Connect** in Wand to find the panel link, or open `http://YOUR-PC-LAN-IP:3223/remote/` in the phone browser. Replace `YOUR-PC-LAN-IP` with the PC's actual local address.
4. Wait for **Connected**, then open **Library**.

Do not use `localhost` on the phone. That points to the phone itself.

## Optional: let Phone Helper find the link

The [Wand Phone Helper](../PhoneHelper/README.md) is installed separately for each Windows account that needs it.

Open it, select your network adapter and use **Refresh connection**. Scan its QR code or copy the displayed link into your phone browser. If access is blocked, its trusted-network option can request a scoped firewall allowance after your approval. Read the helper guide for the exact behavior.

The helper's video-guide button opens a YouTube search for the title you enter. It is a search shortcut, not a built-in video player.

## Make it your loadout

| Try this | What it does |
| --- | --- |
| Open **Library** | Find a game from Wand's synced library. |
| Pin frequently used controls | Keep those controls in the pinned group. |
| Save a preset | Store persistent trainer values for that game. One-shot button actions are not saved. |
| Reconnect after a network change | Refresh the PC address and reconnect the browser. |

Pins and presets use browser-local storage. Another browser or cleared site data will not carry those preferences over. A connected panel still needs a working game and trainer on the PC.

## Browser tab or home-screen app?

**A browser tab over local HTTP works for the controller.** Home-screen PWA installation requires HTTPS trusted by your phone, which is a separate setup step. Do not assume an installable phone app is ready just because the page opens.

Offline caching keeps the interface available. It cannot control a disconnected game or trainer.

## Keep the controls in your room

The panel has **no pairing authentication**. Anyone who can reach its port can control the active trainer. Use a trusted local network and never forward port `3223` to the internet.

If the phone cannot connect, check the PC's current LAN address, guest-network isolation, phone VPN and the relevant firewall rule. Keep firewall and antivirus protection enabled. [Connection troubleshooting](RESPAWN-GUIDE.md#phone-will-not-connect).
