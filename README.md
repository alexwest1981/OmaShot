# OmaShot 📸✨

A fast, interactive **Screenshot Manager & Quick Capture status bar widget** built natively for **[Omarchy](https://omarchy.org)** and **Quickshell**.

View instant high-resolution previews of recent screenshots, edit and annotate with a single click, browse full screenshot history, and effortlessly share screenshots with system tools and AI coding assistants (**Antigravity**, **Claude in VS Code**, **Gemini CLI**).

---

## ✨ Features

* **📸 Quick Capture in Top Bar:**
  * Left-click: Open interactive preview & gallery popup.
  * Right-click: Instant interactive region selection (`omarchy-capture-screenshot smart`).
  * Middle-click: Fullscreen capture.
* **🖼️ Instant High-Res Preview (Flik 1):**
  * Displays the latest or selected screenshot with crisp aspect ratio fit.
  * Shows exact pixel resolution (`1920 × 1080 px`), file size (`240 KB`), and relative timestamps (`Idag 13:12`, `Nyss`).
* **🤖 AI & System-Wide Integration (Claude, Gemini, Antigravity):**
  * **Auto-Symlinks:** Automatically keeps `~/Pictures/latest-screenshot.png` and `/tmp/latest-screenshot.png` pointing to the newest screenshot. AI assistants can read this path directly anytime!
  * **📋 Kopiera sökväg:** Copies the absolute file path to clipboard so you can paste it straight into chat prompts (`/home/alex/Pictures/screenshot-....png`).
  * **🖼️ Kopiera bild:** Puts raw PNG bytes directly onto the Wayland clipboard (`wl-copy`) for pasting images into chat, browser, or documents.
* **✏️ Integrated Editing & Annotations:**
  * Launch Omarchy's official **Tensaku** annotator (`tensaku-edit`) or **Pinta** with one click to crop, draw arrows, boxes, or blur sensitive regions.
* **👁️ Fullscreen Viewer:**
  * Open screenshots in **imv** / system image viewer.
* **📜 Screenshot History Gallery (Flik 2):**
  * Scrollable visual history of previous screenshots in `~/Pictures`.
  * Live thumbnails, timestamps, and quick action icons on every row (`✏️` Redigera, `👁️` Visa, `📋` Kopiera, `🗑️` Ta bort).
* **🗑️ Safe File Deletion:**
  * Delete unneeded screenshots directly from the UI with safety confirmation.

---

## 📦 Installation

### 1. Clone into Omarchy plugins directory

```bash
git clone https://github.com/alexwest1981/OmaShot.git ~/.config/omarchy/plugins/custom.screenshots
```

### 2. Enable in `~/.config/omarchy/shell.json`

Add `custom.screenshots` to `bar.layout.right`:

```json
{
  "bar": {
    "layout": {
      "right": [
        { "id": "custom.email" },
        { "id": "custom.screenshots" },
        { "id": "omarchy.tray" }
      ]
    }
  }
}
```

### 3. Restart Omarchy Shell

```bash
omarchy-restart-shell
```

---

## 🤖 How AI Assistants Access Screenshots

OmaShot makes all screenshots instantly accessible across your entire development environment:

1. **Direct Path Symlink:**
   Ask Antigravity, Claude, or Gemini:
   > *"Kolla på skärmdumpen i `~/Pictures/latest-screenshot.png`"*
2. **One-Click Path Copy:**
   Click **`📋 Kopiera sökväg`** in OmaShot, then paste (`Ctrl+V`) into your prompt:
   > *"Kika på denna skärmdump: `/home/alex/Pictures/screenshot-2026-09-02_17-13-51.png`"*
3. **Image Data Clipboard:**
   Click **`🖼️ Kopiera bild`** and paste (`Ctrl+V`) into chat interfaces supporting image uploads.

---

## 🖱️ Controls & Shortcuts

| Action | Control |
| :--- | :--- |
| **Öppna galleri / Preview** | Vänsterklicka på kameraikonen `󰄀` |
| **Ta skärmdump (Område)** | Högerklicka på ikonen eller klicka på `✂️ Område` i popupen |
| **Ta skärmdump (Helskärm)** | Mittenklicka på ikonen eller klicka på `🖥️ Helskärm` i popupen |
| **Redigera bild** | Klicka på `✏️ Redigera / Rita` (öppnar Tensaku/Pinta) |
| **Visa fullstorlek** | Klicka på preview-bilden eller `👁️ Visa fullstorlek` (öppnar imv) |
| **Kopiera filväg** | Klicka på `📋 Kopiera sökväg` |
| **Kopiera bild till urklipp** | Klicka på `🖼️ Kopiera bild` |
| **Ta bort skärmdump** | Klicka på `🗑️ Ta bort denna skärmdump` |

---

## 📄 License

MIT License © 2026 [Alex Weström](https://github.com/alexwest1981)
