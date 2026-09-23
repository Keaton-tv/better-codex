<p align="center">
  <img src="assets/hero.svg" alt="Codex Model Slider — Luna High, Sol Medium, Astra Low. Three presets, one slider." width="100%">
</p>

<h1 align="center">Codex Model Slider</h1>

<p align="center"><strong>Your go-to model + reasoning combinations, on the native Codex slider.</strong></p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-111827?style=flat-square" alt="Platform: macOS">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-3B82F6?style=flat-square" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/languages-English%20%2F%20%E4%B8%AD%E6%96%87-6366F1?style=flat-square" alt="English and Chinese">
</p>

**English** · [简体中文](README.zh-CN.md) · [Quick start](#quick-start) · [Why these presets?](#why-these-presets)

| Slide to switch | Double-click to launch | Runtime handled |
| :--- | :--- | :--- |
| Select model + reasoning together | Install once, launch from your Desktop | Node.js checked, downloaded and verified when needed |

This fork uses Keaton's preferred GPT-6 presets. The original project is [cabbagecabbage/codex-model-slider](https://github.com/cabbagecabbage/codex-model-slider).

## See the presets

| Luna High | Sol Medium | Astra Low |
| :---: | :---: | :---: |
| GPT-6 Luna · high | GPT-6 Sol · medium | GPT-6 Astra · low |

## Quick start

Open Terminal on macOS, paste this one line, and press Return:

```bash
(set -o pipefail; curl -fsSL https://raw.githubusercontent.com/Keaton-tv/better-codex/main/install.sh | /bin/bash)
```

**Codex-Model-Slider.command** appears on your Desktop with a hidden cache helper beside it. Finish active Codex tasks, double-click it, and wait for **Three presets loaded / 三档已加载**. Then use the native slider. Next time, just double-click the desktop file. Installer and launcher messages are shown in both English and Chinese.

**Requirements:** macOS; the app at `/Applications/ChatGPT.app`; Node.js is checked and prepared automatically, with no manual installation; an account with access to the selected models and reasoning levels. This tool does not unlock models or increase usage limits.

<details>
<summary><strong>Manual download & launch details</strong></summary>

Alternatively, choose **Code → Download ZIP**, extract it, and run [Codex-Model-Slider.command](Codex-Model-Slider.command) from the extracted folder with [cache-indicator.mjs](cache-indicator.mjs) beside it. To install that copy on your Desktop, type `bash ` in Terminal, drag in the extracted `install.sh`, append ` --local`, and press Return.

Installation downloads the launcher and read-only cache helper. It does not launch or quit the app and needs no `sudo`. Existing slider files are never overwritten: move them aside before reinstalling or updating. [Inspect the installer](install.sh).

If the app is running, you have five seconds to cancel with Ctrl+C before the script requests a normal quit and relaunch. If automatic quitting fails, quit manually with ⌘Q when prompted.

</details>

## Why this project?

A few model-and-reasoning combinations cover most of the author's daily workflow. Selecting both settings repeatedly adds friction. This script places those combinations on the native slider so one movement selects both settings.

## Why these presets?

This fork uses these three combinations:

| Preset | Intended use | Personal trade-off |
| --- | --- | --- |
| **Luna High** | Focused tasks | Lower usage |
| **Sol Medium** | Everyday work | Balanced speed and depth |
| **Astra Low** | More demanding work | Stronger model with lighter reasoning |

Choose directly for the task. The positions are not a universal scale of speed, price or capability.

## Cache status beside the composer

After launching through the Desktop file, a compact `Cache ~29m` estimate appears beside the context indicator for local tasks. It reads cache token counts from Codex's local rollout files. A question mark means there is no recent confirmed cache read or write, or the 30-minute minimum window has elapsed. The next actual request confirms whether a prefix was reused. The helper sends no keep-warm messages.

This feature was inspired by [CodexZero's cache indicator](https://github.com/Retro2512/CodexZero). It uses a small background process while the app is open and stops after the app exits. Codex's app files remain unchanged.

## Under the hood

<details>
<summary><strong>Customize your presets</strong></summary>

Edit `presets` near the top of `Codex-Model-Slider.command`, keep three supported combinations, then launch again:

```js
const presets=[
  {model:'gpt-6-luna',reasoning_effort:'high'},
  {model:'gpt-6-sol',reasoning_effort:'medium'},
  {model:'gpt-6-astra',reasoning_effort:'low'},
];
```

Use IDs and reasoning levels supported by your account and client. The terminal success message has fixed preset names; update those too if desired.

</details>

<details>
<summary><strong>How it works & restore defaults</strong></summary>

The script launches the official app with a temporary local debugging port, connects to its `app://-/` UI over the Chromium DevTools Protocol (CDP), wraps the in-memory Statsig `getDynamicConfig` method, replaces only `presets` in config `423260384`, and emits `values_updated`. The app still handles selection, setting persistence and availability checks.

No ASAR, Info.plist, app source, signature or persistent preset file is modified. A page reload or app exit removes the override.

**To restore the original slider, fully quit the app and launch it normally from the Dock.** The app may retain the model you selected; restoring the slider does not reset conversation settings.

</details>

<details>
<summary><strong>Automatic downloads, file locations & removal</strong></summary>

1. **Desktop installation:** download the launcher and hidden cache helper from this repository. Do not launch the app or overwrite existing slider files.
2. **Prepare on double-click:** check the fixed app path and a usable Node.js runtime. Download only when no compatible runtime is available.
3. **Launch when ready:** use the original normal quit/relaunch flow and apply the slider. The five-second cancellation window remains.

On first launch, the script reuses a compatible bundled or local Node.js. If neither works, it downloads Node.js 22.23.2 for Apple Silicon or Intel from the [official Node.js site](https://nodejs.org/dist/v22.23.2/), verifies SHA-256, and caches it in `~/Library/Application Support/Codex Model Slider`. Later launches reuse it. No Homebrew, administrator password, PATH setup or system Node.js replacement is needed. The first download needs internet access; approve macOS permission prompts as needed.

Official archive SHA-256 digests are pinned in the script and checked before extraction or execution. Failed downloads or checksums clean up temporary files and stop before restarting the app; double-click again to retry. The cached runtime is private to this tool, with the official license included.

**Remove:** delete the desktop launcher and `~/Desktop/.Codex-Cache-Indicator.mjs`. If Node.js was automatically downloaded, use Finder → Go to Folder to open `~/Library/Application Support/Codex Model Slider` and remove this tool-specific directory too. Keep any other Node.js installations. Restoring the original slider and removing the cache indicator only requires fully quitting and launching the app normally.

</details>

<details>
<summary><strong>Troubleshooting</strong></summary>

- **Permission denied:** type `chmod +x ` in Terminal, drag the extracted `.command` file into the window, press Return, and double-click the file again.
- **macOS blocks opening:** inspect the script and verify its source, then follow System Settings → Privacy & Security to allow it. Do not disable system security protections.
- **Automation permission:** Terminal may need permission to control Codex so the app can quit normally.
- **Only one model's reasoning levels appear:** try “Reset to default” in the original selector, then check the model names.
- **Node.js download fails:** check your connection and double-click again. Preparation failures do not quit or launch the app.
- **Loading fails:** the internal interface may have changed. Fully quit and launch normally to restore the original slider.

</details>

## Compatibility and limits

- Unofficial and dependent on internal interfaces. App updates may break it. There is no version, signature or archive fingerprint verification or automatic adaptation.
- The debugging port is launched with `127.0.0.1` and remains open for that app session. It allows page execution: do not forward it or share it with untrusted programs. Fully quitting the app closes it.
- The script requires no API key, reads local rollout files to find cache token counts, and saves no diagnostic logs or session files. It does not display or send chat content. The app itself still connects to its services.
- The verified app name, path and slider behavior are preserved; user-facing messages are bilingual. Desktop installation and automatic Node.js preparation are covered by syntax and isolated behavior checks. No fresh live-app relaunch or UI acceptance test was performed.

<details>
<summary><strong>Official reference</strong></summary>

Official model parameter reference: [GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra). API documentation does not imply support for this internal client interface or availability on every account.

</details>

---

Code and documentation: [MIT License](LICENSE). Product UI and trademarks in screenshots belong to their respective owners. This project is not affiliated with or endorsed by OpenAI.
