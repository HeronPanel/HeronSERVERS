# 🦅 HERON SERVER

**HERON SERVER** is a simple, colorful, terminal-based **Minecraft (PaperMC) Server Manager**. With a single script you can create, start, rename, delete, and uninstall multiple Minecraft servers — no manual setup hassle required.

```
██╗  ██╗███████╗██████╗  ██████╗ ███╗   ██╗
██║  ██║██╔════╝██╔══██╗██╔═══██╗████╗  ██║
███████║█████╗  ██████╔╝██║   ██║██╔██╗ ██║
██╔══██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║
██║  ██║███████╗██║  ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
```

---

## ✨ Features

- 🎨 Big colorful ASCII banner + easy-to-use menu
- 🆕 **Create New Server** — enter a name, pick a version, the jar downloads automatically
- ▶️ **Start Server** — launch any of your servers with one click
- 🗑️ **Delete Server** — remove a server with a confirmation prompt
- ✏️ **Rename Server** — rename a server without losing any data
- ❌ **Uninstall Server** — fully wipe a server (with an extra safety confirmation)
- ⚙️ **Settings** — default RAM, auto-accept EULA, servers directory — all customizable
- 📦 Manage multiple servers at once, each in its own folder
- 🧠 Each server stores its own metadata (`version`, `RAM`, `created date`)

---

## 📋 Requirements

| Requirement | Details |
|---|---|
| **OS** | Linux / macOS / WSL (Bash shell) |
| **Java** | Java 17+ (Java 21 recommended for the latest Paper versions) |
| **wget** or **curl** | Needed to download the server jar |
| **Internet Connection** | Required to download PaperMC server files |

To install Java (Debian/Ubuntu):
```bash
sudo apt update && sudo apt install openjdk-21-jre-headless -y
```

---

## 🚀 Installation

   ```bash
   bash <(curl -s https://raw.githubusercontent.com/HeronPanel/HeronSERVERS/refs/heads/main/create.sh)
   ```
---

## 🖥️ Usage / Menu Guide

As soon as you run the script, you'll see this menu:

```
1) Create New Server
2) Start Server
3) Delete Server
4) Rename Server
5) Uninstall Server
6) Settings
7) Exit
```

### 1️⃣ Create New Server
- You'll be asked for a **Server Name** → a folder is created at `~/HeronServers/<name>` and the script automatically `cd`s into it
- You then choose a **Version**:
  | Option | Version |
  |---|---|
  | 1 | 1.21.11 (Latest) |
  | 2 | 1.21.5 |
  | 3 | 1.21.1 |
  | 4 | 1.21 |
  | 5 | 1.20 |
- The **PaperMC jar** for the selected version is automatically downloaded via `wget` (saved as `server.jar`)
- You'll be asked for **RAM** (max) — press Enter to use the default
- The following files are auto-generated:
  - `eula.txt` (auto-set to `eula=true`)
  - `server.properties` (basic config + HERON SERVER MOTD)
  - `start.sh` (server launch script)
  - `.heron_meta` (server info)

### 2️⃣ Start Server
- You'll see a list of created servers → pick a number → the server starts
- To stop the server, type `stop` in the terminal or press `CTRL+C`

### 3️⃣ Delete Server
- Select a server → confirm with `yes` → the server folder is permanently deleted

### 4️⃣ Rename Server
- Select a server → give it a new name → the folder is renamed

### 5️⃣ Uninstall Server
- Select a server → for safety, you must type the exact word **`UNINSTALL`** → only then will it be removed

### 6️⃣ Settings
| Setting | Description |
|---|---|
| Default Max RAM | Default `-Xmx` value used for new servers |
| Default Min RAM | Default `-Xms` value used for new servers |
| Auto-accept EULA | `true`/`false` — controls the `eula.txt` for new servers |
| Servers Directory | Where servers are stored (default: `~/HeronServers`) |

Settings are saved in `~/.heron/config.cfg`, so they persist across restarts.

---

## 📁 Folder Structure

```
~/.heron/
└── config.cfg              # Global settings

~/HeronServers/
└── MyServer/
    ├── server.jar
    ├── eula.txt
    ├── server.properties
    ├── start.sh
    └── .heron_meta
```

---

## ⚠️ Notes

- The default server port is `25565` — don't forget to port-forward on your router/firewall if you want online multiplayer.
- Check your system's available RAM before allocating a large amount.
- Both `Uninstall` and `Delete` are **permanent** — there's no undo/recycle bin, so keep backups of any important worlds.

---
## 📝 License

Free to use, modify, and share. Made with ❤️ for Minecraft server admins.
