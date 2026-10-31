# Wazuh endpoint agent for ThinStation

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

The agent service is conditioned on `/var/prstnt` being a mounted
persistent volume. The `persistent-files` package is required
to preserve enrollment identity and agent configuration across boots.
Validate that your image restores the identity before the service starts.
Default password or insecure open enrollment is not appropriate for
a deployment of 500 devices.

Check service: `systemctl status wazuh-agent`.
Review logs: `journalctl -u wazuh-agent -b`.
Manager reachability: `nc -vz MANAGER 1514` and `nc -vz MANAGER 1515`.

ThinStation images should be redeployed from a central build pipeline.
Remote Wazuh Active Response should be tightly scoped to vetted scripts;
do not enable arbitrary manager-initiated shell execution.
