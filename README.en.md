# Codex Model Slider

**Customize the native Codex slider with three model and reasoning-effort presets. Double-click to launch on macOS.**

Luna Max → Sol High → Astra Medium. A single script; no app-bundle patching or plugin installation.

[中文说明](README.md) · [Why these presets?](https://github.com/cabbagecabbage/chatgpt-plus-codex-cn-guide/blob/main/docs/model-selection-and-reasoning.md)

## Quick start

1. Choose **Code → Download ZIP** on GitHub and extract the archive.
2. Finish active Codex tasks, then double-click **[三档滑块.command](三档滑块.command)**.
3. Wait for the app to reopen and the terminal to show **三档已加载** (“three presets loaded”). Use the native slider to switch presets.

Launch through the script whenever you want these presets. You can keep it on your desktop. Terminal messages are currently in Chinese.

**Requirements:** macOS; the app at `/Applications/ChatGPT.app`; its bundled Node.js, or an existing Node.js 22+ installation; an account with access to the selected models and reasoning levels. This tool does not unlock models or increase usage limits.

If the app is running, you have five seconds to cancel with Ctrl+C before the script requests a normal quit and relaunch. If automatic quitting fails, quit manually with ⌘Q when prompted.

| Luna Max | Sol High | Astra Medium |
| :---: | :---: | :---: |
| ![Codex slider: GPT-5.6 Luna, maximum reasoning](assets/luna-max.png) | ![Codex slider: GPT-5.6 Sol, high reasoning](assets/sol-high.png) | ![Codex slider: GPT-6 Astra, medium reasoning](assets/astra-medium.png) |
| Simple everyday tasks | Well-defined engineering | Planning and architecture |

Screenshots show an existing UI result; availability depends on your account and app version.

## Troubleshooting

- **Permission denied:** type `chmod +x ` in Terminal, drag the extracted `.command` file into the window, press Return, and double-click the file again.
- **macOS blocks opening:** inspect the script and verify its source, then follow System Settings → Privacy & Security to allow it. Do not disable system security protections.
- **Automation permission:** Terminal may need permission to control Codex so the app can quit normally.
- **Only one model's reasoning levels appear:** try “Reset to default” in the original selector, then check the model names.
- **Node.js missing:** install Node.js 22+; the script does not install dependencies.
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

## Compatibility and limits

- Unofficial and dependent on internal interfaces. App updates may break it. There is no version, signature or archive fingerprint verification or automatic adaptation.
- The debugging port is launched with `127.0.0.1` and remains open for that app session. It allows page execution: do not forward it or share it with untrusted programs. Fully quitting the app closes it.
- The script requires no API key, reads no chat content, and saves no diagnostic logs or session files. The app itself still connects to its services.
- This repository preparation preserves the original script logic, updates its executable permission, and checks syntax. It does not include a fresh live-app relaunch or UI acceptance test.

## Related guide

**[ChatGPT Plus & Codex guide](https://github.com/cabbagecabbage/chatgpt-plus-codex-cn-guide)** (Chinese) covers subscriptions, setup and model selection. This project focuses on applying the presets; their detailed rationale lives in the guide.

Official model parameter reference: [GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra). API documentation does not imply support for this internal client interface or availability on every account.

## License

Code and documentation: [MIT License](LICENSE). Product UI and trademarks in screenshots belong to their respective owners. This project is not affiliated with or endorsed by OpenAI.
