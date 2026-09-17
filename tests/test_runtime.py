"""Isolated runtime bootstrap tests: no app launch, network, or real user cache."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / '三档滑块.command'
ARM_HASH = '61130f394c1630d211dd50aecc4353d379480f36d3ac913cd85dbba1aed585c6'
X64_HASH = '58e99022c2ff89395576cc7fd4d98cea24bb68081475d5f88b801ee8729fb026'


class RuntimeTests(unittest.TestCase):
    def run_case(self, body, success=True):
        with tempfile.TemporaryDirectory(prefix='slider-runtime-') as tmp:
            env = dict(os.environ, SLIDER_FIXTURE=tmp, SLIDER_SCRIPT=str(LAUNCHER),
                       CODEX_SLIDER_RUNTIME_DIR=tmp + '/cache with spaces')
            script = r'''
set -euo pipefail
source "$SLIDER_SCRIPT"
RUNTIME_STAGING=''
trap finish EXIT
# No real runtimes, network, archive extraction or app calls in these tests.
node_usable() { [[ "$1" = "$SLIDER_FIXTURE/"* ]] && [ -f "$1" ] && [ "$(cat "$1")" = compatible ]; }
uname() { printf '%s\n' "${TEST_ARCH:-arm64}"; }
curl() {
  printf 'download\n' >> "$SLIDER_FIXTURE/events"
  [ "${FAIL_DOWNLOAD:-0}" = 0 ] || return 22
  while [ "$#" -gt 0 ]; do
    if [ "$1" = --output ]; then shift; printf archive > "$1"; return; fi
    shift
  done
  return 2
}
shasum() { printf '%s  archive\n' "${TEST_HASH:-ARM_HASH}"; }
tar() {
  printf 'extract\n' >> "$SLIDER_FIXTURE/events"
  local arch="${TEST_ARCH:-arm64}"
  [ "$arch" != x86_64 ] || arch=x64
  local unpack="$RUNTIME_STAGING/node-v22.23.2-darwin-$arch"
  mkdir -p "$unpack/bin"
  printf '%s' "${EXTRACTED_NODE:-compatible}" > "$unpack/bin/node"
  printf license > "$unpack/LICENSE"
}
'''.replace('ARM_HASH', ARM_HASH)
            result = subprocess.run(['/bin/bash', '-c', script + '\n' + body],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
            self.assertFalse(list(Path(env['CODEX_SLIDER_RUNTIME_DIR']).glob('.download.*')))
            return result

    def test_bundled_runtime_wins_without_network(self):
        self.run_case(r'''
node_usable() { [ "$1" = /Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node ]; }
prepare_node
[ "$NODE" = /Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node ]
[ ! -e "$SLIDER_FIXTURE/events" ]
''')

    def test_path_runtime_without_network(self):
        self.run_case(r'''
node_usable() { [ "$1" = "$(command -v node)" ]; }
prepare_node
[ "$NODE" = "$(command -v node)" ]
[ ! -e "$SLIDER_FIXTURE/events" ]
''')

    def test_download_then_cache_reuse(self):
        self.run_case(r'''
prepare_node
[ "$(cat "$NODE")" = compatible ]
[ -f "$(dirname "$(dirname "$NODE")")/LICENSE" ]
prepare_node
[ "$(cat "$SLIDER_FIXTURE/events")" = $'download\nextract' ]
''')

    def test_intel(self):
        self.run_case('TEST_ARCH=x86_64\nTEST_HASH=' + X64_HASH + r'''
prepare_node
[[ "$NODE" = *darwin-x64/bin/node ]]
''')

    def test_bad_cache_replaced(self):
        self.run_case(r'''
mkdir -p "$CODEX_SLIDER_RUNTIME_DIR/node-v22.23.2-darwin-arm64/bin"
printf outdated > "$CODEX_SLIDER_RUNTIME_DIR/node-v22.23.2-darwin-arm64/bin/node"
prepare_node
[ "$(cat "$NODE")" = compatible ]
''')

    def test_download_failure_stops(self):
        self.run_case('FAIL_DOWNLOAD=1\nprepare_node\n', success=False)

    def test_checksum_failure_stops_before_extract(self):
        self.run_case(r'''
TEST_HASH=bad
if (set -e; prepare_node); then exit 1; fi
[ "$(cat "$SLIDER_FIXTURE/events")" = download ]
# prepare_node above ran in a subshell; clean its isolated fixture staging.
rm -rf "$CODEX_SLIDER_RUNTIME_DIR"/.download.*
''')

    def test_incompatible_download_stops(self):
        self.run_case('EXTRACTED_NODE=incompatible\nprepare_node\n', success=False)

    def test_unsupported_architecture(self):
        self.run_case('TEST_ARCH=unknown\nprepare_node\n', success=False)

    def test_capability_probe(self):
        # Fake executable evaluates only the probe source in the actual local Node.
        node = subprocess.check_output(['which', 'node'], text=True).strip()
        with tempfile.TemporaryDirectory(prefix='slider-probe-') as tmp:
            fake = Path(tmp) / 'node'
            for version, missing, expected in [('20.1.0', False, False),
                                                ('22.23.2', True, False),
                                                ('22.23.2', False, True)]:
                fake.write_text('#!/bin/bash\nexec "$REAL_NODE" --input-type=module -e '
                                '\'Object.defineProperty(process.versions,"node",{value:"' + version +
                                '"});' + ('globalThis.WebSocket=undefined;' if missing else '') +
                                '\'"${3}"\n')
                fake.chmod(0o755)
                result = subprocess.run(['/bin/bash', '-c',
                                         'source "$SLIDER_SCRIPT"; node_usable "$FAKE_NODE"'],
                                        env=dict(os.environ, REAL_NODE=node, FAKE_NODE=str(fake),
                                                 SLIDER_SCRIPT=str(LAUNCHER)))
                self.assertEqual(result.returncode == 0, expected)


if __name__ == '__main__':
    unittest.main()
