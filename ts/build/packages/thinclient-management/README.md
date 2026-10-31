This metapackage selects the Cockpit web management console and Wazuh endpoint agent.

Enable `package thinclient-management` in build.conf. Configure each endpoint's `/etc/wazuh-agent/manager.conf` and provide a durable `/var/prstnt` mount for Wazuh identity. Cockpit listens on HTTPS TCP/9090; restrict it to a management VLAN/VPN. Wazuh agent needs manager TCP/1514 and enrollment TCP/1515. Do not bundle enrollment secrets or shared client keys.
