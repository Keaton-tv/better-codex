# Codex Model Slider

**Customize the native Codex slider with three model and reasoning-effort presets. Double-click to launch on macOS.**

Luna Max → Sol High → Astra Medium. A single script; no app-bundle patching or plugin installation.

[中文说明](README.md) · [Why these presets?](https://github.com/cabbagecabbage/chatgpt-plus-codex-cn-guide/blob/main/docs/model-selection-and-reasoning.md)

## Quick start

Open Terminal on macOS, paste this one line, and press Return:

```bash
(set -o pipefail; curl -fsSL https://raw.githubusercontent.com/cabbagecabbage/codex-model-slider/main/install.sh | /bin/bash)
```

**三档滑块.command** appears on your Desktop. Finish active Codex tasks, double-click it, and wait for **三档已加载** (“three presets loaded”). Then use the native slider. Next time, just double-click the desktop file. Launcher messages are currently in Chinese.

Installation downloads the launcher and makes it executable. It does not launch or quit the app and needs no `sudo`. An existing file with the same name is never overwritten: move it aside before reinstalling or updating. [Inspect the installer](install.sh).

**Requirements:** macOS; the app at `/Applications/ChatGPT.app`; Node.js is checked and prepared automatically, with no manual installation; an account with access to the selected models and reasoning levels. This tool does not unlock models or increase usage limits.

If the app is running, you have five seconds to cancel with Ctrl+C before the script requests a normal quit and relaunch. If automatic quitting fails, quit manually with ⌘Q when prompted.

| Luna Max | Sol High | Astra Medium |
| :---: | :---: | :---: |
| ![Codex slider: GPT-5.6 Luna, maximum reasoning](assets/luna-max.png) | ![Codex slider: GPT-5.6 Sol, high reasoning](assets/sol-high.png) | ![Codex slider: GPT-6 Astra, medium reasoning](assets/astra-medium.png) |
| Simple everyday tasks | Well-defined engineering | Planning and architecture |

Screenshots show an existing UI result; availability depends on your account and app version.

## Manual download

Alternatively, choose **Code → Download ZIP**, extract it, and double-click [三档滑块.command](三档滑块.command). To install that copy on your Desktop, type `bash ` in Terminal, drag in the extracted `install.sh`, append ` --local`, and press Return.

## Troubleshooting

- **Permission denied:** type `chmod +x ` in Terminal, drag the extracted `.command` file into the window, press Return, and double-click the file again.
- **macOS blocks opening:** inspect the script and verify its source, then follow System Settings → Privacy & Security to allow it. Do not disable system security protections.
- **Automation permission:** Terminal may need permission to control Codex so the app can quit normally.
- **Only one model's reasoning levels appear:** try “Reset to default” in the original selector, then check the model names.
- **Node.js download fails:** check your connection and double-click again. Preparation failures do not quit or launch the app.
- **Loading fails:** the internal interface may have changed. Fully quit and launch normally to restore the original slider.

## Why this project?

A few model-and-reasoning combinations cover most of the author's daily workflow. Selecting both settings repeatedly adds friction. This script places those combinations on the native slider so one movement selects both settings.

The defaults reflect personal experience, not controlled benchmarks:

| Preset | Intended use | Personal trade-off |
| --- | --- | --- |
| **Luna Max** | Simple tasks without urgency | Prioritize usage allowance over waiting time |
| **Sol High** | Engineering with clear requirements and testable acceptance criteria | Prioritize implementation and progress |
| **Astra Medium** | Planning, architecture, mechanisms and Skill design | Prioritize judgment and fewer revisions |

Choose directly for the task. The positions are not a universal scale of speed, price or capability.

Read the companion **[model selection and reasoning analysis](https://github.com/cabbagecabbage/chatgpt-plus-codex-cn-guide/blob/main/docs/model-selection-and-reasoning.md)** (Chinese) for the rationale. Its historical benchmark section has a separate scope and does not prove the relative performance or subscription usage of these three presets.

## Customize the presets

Edit `presets` near the top of `三档滑块.command`, keep three supported combinations, then launch again:

```js
const presets=[
  {model:'gpt-5.6-luna',reasoning_effort:'max'},
  {model:'gpt-5.6-sol',reasoning_effort:'high'},
  {model:'gpt-6-astra',reasoning_effort:'medium'},
];
```

Use IDs and reasoning levels supported by your account and client. The terminal success message has fixed preset names; update those too if desired.

## How it works and how to undo it

The script launches the official app with a temporary local debugging port, connects to its `app://-/` UI over the Chromium DevTools Protocol (CDP), wraps the in-memory Statsig `getDynamicConfig` method, replaces only `presets` in config `423260384`, and emits `values_updated`. The app still handles selection, setting persistence and availability checks.

No ASAR, Info.plist, app source, signature or persistent preset file is modified. A page reload or app exit removes the override.

**To restore the original slider, fully quit the app and launch it normally from the Dock.** The app may retain the model you selected; restoring the slider does not reset conversation settings.

## What does the script do?

1. **Desktop installation:** download the launcher from this repository and make it executable. Do not launch the app or overwrite an existing desktop file.
2. **Prepare on double-click:** check the fixed app path and a usable Node.js runtime. Download only when no compatible runtime is available.
3. **Launch when ready:** use the original normal quit/relaunch flow and apply the slider. The five-second cancellation window remains.

On first launch, the script reuses a compatible bundled or local Node.js. If neither works, it downloads Node.js 22.23.2 for Apple Silicon or Intel from the [official Node.js site](https://nodejs.org/dist/v22.23.2/), verifies SHA-256, and caches it in `~/Library/Application Support/Codex Model Slider`. Later launches reuse it. No Homebrew, administrator password, PATH setup or system Node.js replacement is needed. The first download needs internet access; approve macOS permission prompts as needed.

Official archive SHA-256 digests are pinned in the script and checked before extraction or execution. Failed downloads or checksums clean up temporary files and stop before restarting the app; double-click again to retry. The cached runtime is private to this tool, with the official license included.

**Remove:** delete the desktop launcher. If Node.js was automatically downloaded, use Finder → Go to Folder to open `~/Library/Application Support/Codex Model Slider` and remove this tool-specific directory too. Keep any other Node.js installations. Restoring the original slider only requires fully quitting and launching the app normally.

## Compatibility and limits

- Unofficial and dependent on internal interfaces. App updates may break it. There is no version, signature or archive fingerprint verification or automatic adaptation.
- The debugging port is launched with `127.0.0.1` and remains open for that app session. It allows page execution: do not forward it or share it with untrusted programs. Fully quitting the app closes it.
- The script requires no API key, reads no chat content, and saves no diagnostic logs or session files. The app itself still connects to its services.
- The original app name, path and slider JavaScript remain unchanged. Desktop installation and automatic Node.js preparation are covered by syntax and isolated behavior checks. No fresh live-app relaunch or UI acceptance test was performed.

## Related guide

**[ChatGPT Plus & Codex guide](https://github.com/cabbagecabbage/chatgpt-plus-codex-cn-guide)** (Chinese) covers subscriptions, setup and model selection. This project focuses on applying the presets; their detailed rationale lives in the guide.

Official model parameter reference: [GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra). API documentation does not imply support for this internal client interface or availability on every account.

## License

Code and documentation: [MIT License](LICENSE). Product UI and trademarks in screenshots belong to their respective owners. This project is not affiliated with or endorsed by OpenAI.
