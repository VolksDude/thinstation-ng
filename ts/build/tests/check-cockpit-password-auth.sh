#!/usr/bin/env bash
# Static contract test: Cockpit must use the ThinStation user password.
# A real boot and login test is still needed for PAM verification.
set -euo pipefail

build_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_script="$build_root/build"
pam_config="$build_root/packages/cockpit/build/extra/etc/pam.d/cockpit"
package_install="$build_root/packages/cockpit/build/install"
finalizer="$build_root/packages/cockpit/build/finalize"

test -f "$pam_config"
grep -Fq 'ts_tsuserpasswd' "$build_script"
grep -Fq 'tsuser:$GETPASSWD:1000:1000:' "$build_script"
grep -Fq 'pam_unix.so' "$pam_config"
grep -Eq '^auth[[:space:]]+required[[:space:]]+pam_unix[.]so' "$pam_config"
grep -Eq '^account[[:space:]]+required[[:space:]]+pam_unix[.]so' "$pam_config"
grep -Eq '^auth[[:space:]]+requisite[[:space:]]+pam_succeed_if[.]so uid = 1000' "$pam_config"
if grep -Eq '^([[:space:]]*(auth|account|session)[[:space:]]+.*(password-auth|pam_permit[.]so))' "$pam_config"; then
    echo "Cockpit PAM must not rely on missing Fedora password-auth or bypass passwords" >&2
    exit 1
fi
grep -Fq 'repackage -e' "$package_install"
grep -Fq 'cockpit.socket' "$finalizer"
grep -Fq 'UID 1000' "$pam_config"
echo "Cockpit authentication is configured for the ThinStation tsuser password"
