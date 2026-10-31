#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for name in cockpit wazuh-agent thinclient-management; do
  base="$root/packages/$name"
  for file in .dna .wind .unwind dependencies; do
    [ -f "$base/$file" ] || { echo "Missing $base/$file" >&2; exit 1; }
  done
done
grep -qx cockpit "$root/packages/thinclient-management/dependencies"
grep -qx wazuh-agent "$root/packages/thinclient-management/dependencies"
grep -q "cockpit-ws" "$root/packages/cockpit/build/install"
grep -q "wazuh-agent" "$root/packages/wazuh-agent/build/install"
grep -q "ConditionPathIsMountPoint=/var/prstnt" "$root/packages/wazuh-agent/build/extra/etc/systemd/system/wazuh-agent.service.d/thinstation.conf"
grep -qx /var/ossec/etc/client.keys "$root/packages/wazuh-agent/build/extra/etc/persistent-files.d/wazuh-agent"
grep -qx /var/ossec/etc "$root/packages/wazuh-agent/build/extra/etc/persistent-dirs.d/wazuh-agent"
for file in "$root/packages/wazuh-agent/build/install" "$root/packages/wazuh-agent/build/remove"; do bash -n "$file"; done
python3 - "$root/packages/wazuh-agent/build/extra/usr/bin/thinstation-wazuh-configure" <<'PY'
import ast, pathlib, sys
ast.parse(pathlib.Path(sys.argv[1]).read_text())
PY
echo "ThinStation management package static checks passed"
