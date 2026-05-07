# SecureCRT Flatpak

Packages [SecureCRT](https://www.vandyke.com/products/securecrt/) as a Flatpak with full dark theme support on GNOME desktops (Ubuntu, Fedora, etc.).

## Features

- Picks up the host GTK theme automatically via XDG Desktop Portal — no hardwired theme names
- Dark mode works: reads `org.freedesktop.appearance color-scheme` and selects the correct `-dark` theme variant
- Ships necessary compatibility libs (`libicu`, `libkrb5`, `libjpeg`, `libxcb-cursor`) so it runs on any freedesktop-runtime host
- Bundles the GLib schema for `org.gnome.desktop.interface` so `libqgtk3.so` can read theme settings inside the sandbox

## Scope and Security Model

- This package is intentionally a **clean sandboxed SecureCRT app**
- It does **not** expose all host binaries into the SecureCRT local shell
- It does **not** include host-command bridge shims (`docker`, `sudo`, `systemctl`, etc.)

Why:

- Running host binaries directly from `/run/host/...` can fail due to host/runtime ABI mismatches (for example GLIBC version differences)
- Host-command bridging expands privileges and increases attack surface
- Keeping SecureCRT focused on UI + session workflow gives predictable behavior across systems

## Requirements

- A copy of `scrt-*.deb` (purchased from [vandyke.com](https://www.vandyke.com/))
- `flatpak`, `flatpak-builder`, `binutils` installed on the build machine
- `org.freedesktop.Platform//24.08` and `org.freedesktop.Sdk//24.08` from Flathub

## Building locally

```bash
# One-time setup
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08

# Place the .deb in the repo root, then:
bash build.sh
```

Output: `SecureCRT.flatpak`

## Installing

```bash
flatpak install --user --reinstall ./SecureCRT.flatpak

# Install your GTK theme extension (replace with your theme)
flatpak install --user flathub org.gtk.Gtk3theme.Yaru-Blue-dark
```

## Running

```bash
flatpak run com.vandyke.SecureCRT
```

## Building with GitHub Actions

The workflow in `.github/workflows/build.yml` builds automatically. Because the `.deb` is proprietary it is not stored in the repo. Provide the download URL via one of:

| Method | How |
|---|---|
| **Repository variable** | Settings → Variables → `SCRT_DEB_URL` (URL visible in logs) |
| **Repository secret** | Settings → Secrets → `SCRT_DEB_URL` (URL hidden from logs) |
| **Manual trigger** | Actions → "Build SecureCRT Flatpak" → Run workflow → paste URL |

The built `SecureCRT.flatpak` is uploaded as a workflow artifact (retained 30 days).

## Runtime

| Component | Version |
|---|---|
| Flatpak runtime | `org.freedesktop.Platform//24.08` |
| SecureCRT | 9.7.2-3858 |
| Qt | 6 (bundled by SecureCRT) |
