# Wazuh endpoint agent for ThinStation

## Diskless PXE clients: runtime hostname and automatic enrollment

This package supports clients with **no persistent local storage**.
The agent waits for ThinStation's HTTP network configuration, then reads
the Wazuh Manager address and assigned hostname at every boot.

On the HTTP configuration server, in `thinstation.conf.network` or the
appropriate per-host/per-group file, configure:

```ini
NET_HOSTNAME=TC-001
WAZUH_MANAGER=192.0.2.50
```

A dynamic hostname supplied by ThinStation is used when NET_HOSTNAME is
unspecified or contains a wildcard. Wazuh's enrollment agent_name is set
to this hostname. The agent will automatically attempt to enroll if
`/var/ossec/etc/client.keys` is absent; it does not require `/var/prstnt`.

**Important: same hostname is NOT the same agent identity.** Diskless
clients lose their Wazuh authentication key every reboot. Re-enrollment
can create a new manager-assigned agent ID, produce duplicate entries,
or fail due to a duplicate name, according to server configuration.
The manager must explicitly permit controlled re-enrollment/replacement.
This behavior has not been qualified on a live Wazuh manager.
Never assume agent ID or historical continuity is preserved.

For a guaranteed stable ID and history, implement a separate secure,
per-device key/identity service authenticated independently of the
spoofable hostname/MAC address. The existing agent package does not
implement such a service.

Do not expose an unauthenticated enrollment port or distribute a common
enrollment password through HTTP configuration. Deploy TLS-authenticated
manager enrollment, network restrictions, and monitored enrollment rates.
Use a trusted manager CA where supported. Once the image with this feature
is deployed, changing WAZUH_MANAGER in HTTP config does not require
rebuilding the image; a reboot applies the new setting.


This is the endpoint agent, **not** the existing `package wazuh`
(which deploys a Docker-based Wazuh server).

Build using `package wazuh-agent` or the combined `package thinclient-management`.
The agent is pinned by default to Wazuh 4.14.9 (release 1), the
upstream Fedora-compatible x86_64 RPM. The package install recipe
downloads the RPM over HTTPS and rejects failed RPM signatures.

Provision a different Wazuh agent identity for each endpoint.
Configure `/etc/wazuh-agent/manager.conf` with:

```ini
WAZUH_MANAGER=192.0.2.10
# WAZUH_CA_PATH=/etc/wazuh-agent/manager-ca.pem
```

This file must be installed through a deployment-specific overlay
or your first-boot provisioning tooling. The default package includes
only `manager.conf.example`; without the real configuration the agent
will intentionally not start. The agent connects to port 1514/TCP
and enrolls on port 1515/TCP when the manager supports enrollment.
Use TLS verification and manager enrollment authorization in production.
Store any enrollment password at `/var/ossec/etc/authd.pass`
with mode 0600 via a secure enrollment process, not Git or a shared image.

Persistent storage is optional; a diskless agent automatically attempts
enrollment each boot when its key is missing. If persistence is present,
the optional persistent-files configuration can retain the agent key.
Repeated enrollment may create a new Wazuh ID; see the warning above.

Check service: `systemctl status wazuh-agent`.
Review logs: `journalctl -u wazuh-agent -b`.
Manager reachability: `nc -vz MANAGER 1514` and `nc -vz MANAGER 1515`.

ThinStation images should be redeployed from a central build pipeline.
Remote Wazuh Active Response should be tightly scoped to vetted scripts;
do not enable arbitrary manager-initiated shell execution.
