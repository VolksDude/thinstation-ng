# Cockpit for ThinStation

This optional package bundles the native Fedora Cockpit web server, bridge,
and system pages into a ThinStation image.

Enable it in the **active** `ts/build/build.conf` (or a profile build
configuration):

```
package cockpit
```

Build the image with the usual ThinStation workflow and boot the client.
Cockpit is socket activated and listens on **TCP 9090**. From a management
computer, open `https://THINCLIENT-IP:9090`. The first connection may
show a browser warning for Cockpit's automatically generated certificate.
Deploy a trusted certificate before production use.

**Security and prerequisites:**

* Cockpit authenticates against the thin client's local PAM accounts.
  Configure an admin account and a unique, strong password before allowing
  access. The sample ThinStation build profile's default password
  `pleasechangeme` is **not safe for remote management**.
* Do **not** expose TCP 9090 to the Internet. Restrict it to your
  management VLAN or access it through a VPN. This package does not add
  a firewall exception.
* Cockpit may require system administration authorization via polkit.
  Set up an authorized privileged administrative account according to
  your environment. Inclusion of this package does not grant privileges.
* For server/system controls, Fedora's `cockpit-system` is included.
  Cockpit's software update page is intentionally excluded: ThinStation
  should be rebuilt and redeployed rather than updated through a package
  manager on an endpoint.
* ThinStation's image may be rebuilt on restart. Configuration changes
  made in Cockpit do **not automatically persist** unless the relevant
  files are managed by ThinStation persistence/configuration facilities.
* The Cockpit executable can only manage features actually present in the
  image; terminal tools, storage services and other optional components
  are not automatically installed.
* Browser access should be tested on BIOS/UEFI endpoints separately; this
  package does not change bootloader behavior.

On a running client:

```sh
systemctl status cockpit.socket
ss -lnt | grep ':9090'
journalctl -u cockpit.socket -u cockpit.service
```

For troubleshooting, validate that `cockpit.socket`, `cockpit.service`,
`cockpit-tls`, `cockpit-bridge`, the cockpit PAM service configuration,
and Cockpit's static web assets made it into the image. Verify both
normal login and privileged actions before production rollout.
