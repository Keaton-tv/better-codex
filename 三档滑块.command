#!/bin/bash
# 双击运行。正常退出并重新启动 Codex；不修改应用文件。
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
NODE="/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node"
[ -x "$NODE" ] || NODE="$(command -v node)"
"$NODE" --input-type=module - <<'JS'
import {spawn, execFileSync as run} from 'node:child_process';
import net from 'node:net';
const app='/Applications/ChatGPT.app/Contents/MacOS/ChatGPT';
const presets=[
  {model:'gpt-5.6-luna',reasoning_effort:'max'},
  {model:'gpt-5.6-sol',reasoning_effort:'high'},
  {model:'gpt-6-astra',reasoning_effort:'medium'},
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
    console.log('5 秒后正常退出并重启 Codex；有任务未完成可按 Ctrl+C 取消。');
    await sleep(5000);
    try{run('/usr/bin/osascript',['-e','tell application id "com.openai.codex" to quit'],{timeout:10000});}
    catch{console.log('请手动按 ⌘Q 退出 Codex。');}
    for(let i=0;running();i++){if(i===120)throw Error('等待退出超时');await sleep(500);}
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
  console.log(loaded?'三档已加载：Luna Max → Sol High → Astra Medium':'加载失败；当前版本可能不兼容。完全退出后可正常启动 Codex。');
}catch(e){console.error(e.message);process.exitCode=1;}
JS
printf '\n按回车关闭此窗口…'
read -r _
