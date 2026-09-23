#!/bin/bash
# Double-click to prepare Node.js and restart Codex normally; app files are unchanged.
# 双击运行。自动准备 Node.js，再正常退出并重新启动 Codex；不修改应用文件。

node_usable() {
  [ -x "$1" ] && "$1" --input-type=module -e \
    'process.exit(Number(process.versions.node.split(".")[0]) >= 22 && typeof WebSocket === "function" && typeof fetch === "function" && typeof AbortSignal.timeout === "function" ? 0 : 1)' >/dev/null 2>&1
}

# Runtime setup only; the original app path and embedded slider code stay unchanged.
# Reuse a working bundled/PATH runtime (Node >=22 with required web APIs).
# Otherwise fetch pinned official Node.js, verify its published SHA-256 before
# extraction/execution, and cache it under the current user's Application Support.
# No sudo, package manager, shell-profile edits, or system Node replacement.
# Failed downloads are removed on exit; a verified runtime is reused next time.
prepare_node() {
  local candidate arch checksum version archive runtime actual
  for candidate in "/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node" \
    "$(command -v node || true)"; do
    if node_usable "$candidate"; then NODE="$candidate"; return 0; fi
  done

  version=v22.23.2
  case "$(uname -m)" in
    arm64) arch=arm64; checksum=61130f394c1630d211dd50aecc4353d379480f36d3ac913cd85dbba1aed585c6 ;;
    x86_64) arch=x64; checksum=58e99022c2ff89395576cc7fd4d98cea24bb68081475d5f88b801ee8729fb026 ;;
    *) printf '%s\n' 'Unsupported processor architecture. / 不支持当前处理器架构。' >&2; return 1 ;;
  esac
  runtime="${CODEX_SLIDER_RUNTIME_DIR:-$HOME/Library/Application Support/Codex Model Slider}/node-$version-darwin-$arch"
  NODE="$runtime/bin/node"
  if node_usable "$NODE"; then return 0; fi
  mkdir -p "$(dirname "$runtime")"
  RUNTIME_STAGING=$(mktemp -d "$(dirname "$runtime")/.download.XXXXXX")
  archive="node-$version-darwin-$arch.tar.gz"
  printf '%s\n' 'Preparing Node.js automatically; no manual installation needed. / 未找到可用的 Node.js，正在自动准备（无需手动安装）…'
  printf 'Source / 来源：nodejs.org；Version / 版本：%s；Architecture / 架构：%s\nSave location / 保存位置：%s\nSHA-256 will be verified; system Node.js is unchanged. / 下载后将校验 SHA-256，不修改系统 Node.js。\n' "$version" "$arch" "$runtime"
  if ! curl --fail --show-error --location --proto '=https' --proto-redir '=https' \
    --connect-timeout 15 --max-time 300 --retry 2 \
    "https://nodejs.org/dist/$version/$archive" --output "$RUNTIME_STAGING/$archive"; then
    printf '%s\n' 'Node.js download failed. Check your connection and double-click again; Codex has not been quit or launched. / Node.js 下载失败。请检查网络后重新双击；尚未退出或启动 Codex。' >&2
    return 1
  fi
  actual=$(shasum -a 256 "$RUNTIME_STAGING/$archive")
  if [ "${actual%% *}" != "$checksum" ]; then
    printf '%s\n' 'Node.js checksum mismatch; stopped. Double-click again to retry. / Node.js 下载校验失败，已停止；请重新双击重试。' >&2
    return 1
  fi
  tar -xzf "$RUNTIME_STAGING/$archive" -C "$RUNTIME_STAGING"
  candidate="$RUNTIME_STAGING/node-$version-darwin-$arch/bin/node"
  if ! node_usable "$candidate"; then
    printf '%s\n' 'Downloaded Node.js cannot run on this macOS. Check system compatibility. / 下载的 Node.js 无法在此 macOS 上运行。请检查系统兼容性。' >&2
    return 1
  fi
  mkdir -p "$runtime/bin"
  cp "$RUNTIME_STAGING/node-$version-darwin-$arch/LICENSE" "$runtime/LICENSE"
  # Same filesystem: only a complete, verified executable becomes the cached runtime.
  mv -f "$candidate" "$NODE"
  printf '%s\n' 'Node.js is ready and will be reused next time. / Node.js 已准备好，以后会自动复用。'
}

finish() {
  local result=$?
  trap - EXIT
  if [ -n "${RUNTIME_STAGING:-}" ]; then rm -rf "$RUNTIME_STAGING"; fi
  if [ "$result" -ne 0 ]; then printf '\nLaunch did not complete. See the message above. / 启动未完成，请查看上方提示。\n' >&2; fi
  if [ -t 0 ]; then printf '\nPress Return to close this window / 按回车关闭此窗口…'; read -r _ || true; fi
  exit "$result"
}

# Sourcing exposes only runtime helpers, for isolated tests.
if [ "${BASH_SOURCE[0]}" != "$0" ]; then return 0; fi
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
RUNTIME_STAGING=''
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
[ "$(uname -s)" = Darwin ] || { printf '%s\n' 'This script requires macOS. / 此脚本仅支持 macOS。' >&2; exit 1; }
[ -x /Applications/ChatGPT.app/Contents/MacOS/ChatGPT ] || {
  printf '%s\n' 'Cannot find /Applications/ChatGPT.app. Make sure the required official app is installed. / 未找到 /Applications/ChatGPT.app，请确认已安装所需的官方应用。' >&2
  exit 1
}
prepare_node

"$NODE" --input-type=module - <<'JS'
import {spawn, execFileSync as run} from 'node:child_process';
import net from 'node:net';
const app='/Applications/ChatGPT.app/Contents/MacOS/ChatGPT';
const presets=[
  {model:'gpt-6-luna',reasoning_effort:'high'},
  {model:'gpt-6-sol',reasoning_effort:'medium'},
  {model:'gpt-6-astra',reasoning_effort:'low'},
];
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const running=()=>run('/bin/ps',['-axo','comm='],{encoding:'utf8'}).split('\n').some(s=>s.trim()===app);
function inject(presets){
  const c=globalThis.__STATSIG__?.firstInstance;
  if(!c)return false;
  if(globalThis.__threePresets)return true;
  const original=c.getDynamicConfig;
  c.getDynamicConfig=function(id,...args){
    const value=original.call(this,id,...args);
    return id==='423260384'?{...value,value:{...value.value,presets:[presets]},
      get:(key,fallback)=>key==='presets'?[presets]:value.get(key,fallback)}:value;
  };
  c.$emt({name:'values_updated'});
  globalThis.__threePresets=true;
  return true;
}
async function apply(url){
  const ws=new WebSocket(url);
  return new Promise(resolve=>{
    const done=value=>{clearTimeout(timer);ws.close();resolve(value);};
    const timer=setTimeout(()=>done(false),3000);
    ws.onerror=()=>done(false);
    ws.onopen=()=>ws.send(JSON.stringify({id:1,method:'Runtime.evaluate',params:{
      expression:`(${inject})(${JSON.stringify(presets)})`,returnByValue:true}}));
    ws.onmessage=e=>{const r=JSON.parse(e.data);if(r.id===1)done(r.result?.result?.value===true);};
  });
}
try{
  if(running()){
    console.log('Codex will quit normally and restart in 5 seconds. Press Ctrl+C to cancel if tasks are active. / 5 秒后正常退出并重启 Codex；有任务未完成可按 Ctrl+C 取消。');
    await sleep(5000);
    try{run('/usr/bin/osascript',['-e','tell application id "com.openai.codex" to quit'],{timeout:10000});}
    catch{console.log('Press ⌘Q to quit Codex manually. / 请手动按 ⌘Q 退出 Codex。');}
    for(let i=0;running();i++){if(i===120)throw Error('Timed out waiting for Codex to quit / 等待退出超时');await sleep(500);}
  }
  const server=net.createServer().listen(0,'127.0.0.1');
  await new Promise((resolve,reject)=>{server.once('listening',resolve);server.once('error',reject);});
  const port=server.address().port;
  await new Promise(r=>server.close(r));
  const child=spawn(app,[`--remote-debugging-address=127.0.0.1`,`--remote-debugging-port=${port}`],{detached:true,stdio:'ignore'});
  await new Promise((resolve,reject)=>{child.once('spawn',resolve);child.once('error',reject);});
  child.unref();
  let loaded=false;
  for(let i=0;i<60&&!loaded;i++){
    await sleep(500);
    try{
      const pages=await fetch(`http://127.0.0.1:${port}/json/list`,{signal:AbortSignal.timeout(1000)}).then(r=>r.json());
      for(const page of pages){
        if(page.type==='page'&&page.url.startsWith('app://-/')&&page.webSocketDebuggerUrl)
          if(await apply(page.webSocketDebuggerUrl)){loaded=true;break;}
      }
    }catch{}
  }
  console.log(loaded?'Three presets loaded / 三档已加载：Luna High → Sol Medium → Astra Low':'Loading failed; this app version may be incompatible. Fully quit and launch Codex normally. / 加载失败；当前版本可能不兼容。完全退出后可正常启动 Codex。');
}catch(e){console.error("Launch failed / 启动失败:",e.message);process.exitCode=1;}
JS
