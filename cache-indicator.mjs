import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const CACHE_MS = 30 * 60_000;
const SESSION_ROOT = path.join(process.env.CODEX_HOME || path.join(os.homedir(), ".codex"), "sessions");
const UUID = /\/local\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})(?:\/|$)/i;
const filesByThread = new Map();
const snapshotsByFile = new Map();

export function readRolloutTail(text, now = Date.now()) {
  let model = null;
  let observedAt = null;
  let lastTotal = null;
  for (const line of text.split("\n")) {
    if (!line) continue;
    let record;
    try { record = JSON.parse(line); } catch { continue; }
    const payload = record.payload || {};
    if (record.type === "turn_context") {
      const next = payload.model ?? payload.collaboration_mode?.settings?.model;
      if (next && next !== model) observedAt = null;
      if (next) model = next;
    } else if (record.type === "compacted") {
      observedAt = null;
    } else if (record.type === "event_msg" && payload.type === "token_count" && payload.info) {
      const total = payload.info.total_token_usage;
      const last = payload.info.last_token_usage;
      if (!last || !total) continue;
      const totalKey = JSON.stringify(total);
      if (totalKey === lastTotal) continue;
      lastTotal = totalKey;
      const input = last.input_tokens ?? last.inputTokens ?? 0;
      const read = last.cached_input_tokens ?? last.cachedInputTokens ?? 0;
      const write = last.cache_write_input_tokens ?? last.cacheWriteInputTokens ?? 0;
      if (input > 0) observedAt = read > 0 || write > 0 ? Date.parse(record.timestamp) : null;
    }
  }
  if (!/^(gpt-6-|gpt-5\.6-)/.test(model ?? "") || !Number.isFinite(observedAt)) {
    return { state: "unknown", model, observedAt: null, remainingMs: null };
  }
  const remainingMs = Math.max(0, observedAt + CACHE_MS - now);
  return { state: remainingMs > 0 ? "likely" : "expired", model, observedAt, remainingMs };
}

export function statusLabel(snapshot) {
  if (snapshot.state === "likely") {
    const minutes = Math.ceil(snapshot.remainingMs / 60_000);
    return { text: `Cache ~${minutes}m`, title: "Estimated time remaining from the last observed cache read or write. The next request confirms reuse." };
  }
  if (snapshot.state === "expired") {
    return { text: "Cache ?", title: "The 30-minute minimum cache window has elapsed. The server may retain it longer; the next request confirms reuse." };
  }
  return { text: "Cache ?", title: "No recent cache read or write was observed for this local task." };
}

async function discoverFiles(id) {
  const existing = filesByThread.get(id);
  if (existing && Date.now() - existing.checkedAt < (existing.files.length ? 60_000 : 10_000)) return existing.files;
  const found = [];
  async function visit(dir) {
    let entries;
    try { entries = await fs.readdir(dir, { withFileTypes: true }); }
    catch (error) { if (error.code === "ENOENT") return; throw error; }
    for (const entry of entries) {
      const file = path.join(dir, entry.name);
      if (entry.isDirectory()) await visit(file);
      else if (entry.isFile() && entry.name.endsWith(".jsonl") && entry.name.includes(id)) found.push(file);
    }
  }
  await visit(SESSION_ROOT);
  filesByThread.set(id, { files: found, checkedAt: Date.now() });
  return found;
}

async function fileSnapshot(file, now) {
  const stat = await fs.stat(file);
  const prior = snapshotsByFile.get(file);
  if (prior?.size === stat.size && prior?.mtimeMs === stat.mtimeMs) {
    return readRolloutTail(prior.text, now);
  }
  const handle = await fs.open(file, "r");
  let text;
  try {
    const start = Math.max(0, stat.size - 4 * 1024 * 1024);
    const buffer = Buffer.alloc(stat.size - start);
    await handle.read(buffer, 0, buffer.length, start);
    text = buffer.toString("utf8");
    if (start) text = text.slice(text.indexOf("\n") + 1);
  } finally { await handle.close(); }
  snapshotsByFile.set(file, { size: stat.size, mtimeMs: stat.mtimeMs, text });
  return readRolloutTail(text, now);
}

async function currentSnapshot(id) {
  const now = Date.now();
  const files = await discoverFiles(id);
  if (!files.length) return { state: "unknown" };
  const candidates = [];
  for (const file of files) {
    try {
      const stat = await fs.stat(file);
      candidates.push({ file, mtimeMs: stat.mtimeMs });
    } catch {}
  }
  candidates.sort((a, b) => b.mtimeMs - a.mtimeMs);
  for (const { file } of candidates) {
    try {
      const snapshot = await fileSnapshot(file, now);
      if (snapshot.model || snapshot.observedAt) return snapshot;
    } catch {}
  }
  return { state: "unknown" };
}

function showCacheStatus(status) {
  const anchor = document.querySelector('span[role="img"][aria-label^="Context usage:"]');
  const old = document.querySelector('[data-keaton-cache-status]');
  if (!status.text) { old?.remove(); return true; }
  if (!anchor) { old?.remove(); return false; }
  const badge = old || document.createElement("span");
  badge.dataset.keatonCacheStatus = "true";
  badge.textContent = status.text;
  badge.title = status.title;
  badge.setAttribute("aria-label", `${status.text}. ${status.title}`);
  badge.style.cssText = "font-size:11px;line-height:18px;white-space:nowrap;opacity:.72;margin-left:6px;color:inherit";
  const parent = anchor.parentElement;
  if (parent?.parentElement && badge.previousElementSibling !== parent) parent.insertAdjacentElement("afterend", badge);
  return true;
}

async function evaluate(page, status) {
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  return new Promise(resolve => {
    const timer = setTimeout(() => { ws.close(); resolve(false); }, 3000);
    ws.onerror = () => { clearTimeout(timer); resolve(false); };
    ws.onopen = () => ws.send(JSON.stringify({ id: 1, method: "Runtime.evaluate", params: {
      expression: `(${showCacheStatus})(${JSON.stringify(status)})`, returnByValue: true
    }}));
    ws.onmessage = event => {
      const result = JSON.parse(event.data);
      if (result.id !== 1) return;
      clearTimeout(timer);
      ws.close();
      resolve(result.result?.result?.value === true);
    };
  });
}

async function monitor(port) {
  let failures = 0;
  while (failures < 6) {
    try {
      const pages = await fetch(`http://127.0.0.1:${port}/json/list`, { signal: AbortSignal.timeout(2000) }).then(r => r.json());
      failures = 0;
      for (const page of pages) {
        if (page.type !== "page" || !page.url.startsWith("app://-/") || !page.webSocketDebuggerUrl) continue;
        const id = page.url.match(UUID)?.[1];
        await evaluate(page, id ? statusLabel(await currentSnapshot(id)) : { text: "", title: "" });
      }
    } catch { failures++; }
    await new Promise(resolve => setTimeout(resolve, 5000));
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.argv[2]);
  if (Number.isInteger(port) && port > 0 && port < 65536) await monitor(port);
}
