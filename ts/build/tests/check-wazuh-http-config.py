#!/usr/bin/env python3
"""Check Wazuh's HTTP config precedence without requiring an endpoint boot."""
import importlib.machinery
import importlib.util
import pathlib
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
HELPER = ROOT / "packages/wazuh-agent/build/extra/usr/bin/thinstation-wazuh-configure"
loader = importlib.machinery.SourceFileLoader("wazuh_configure", str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class NetworkConfigTests(unittest.TestCase):
    def test_http_overrides_fallback_and_does_not_execute_shell(self):
        with tempfile.TemporaryDirectory() as td:
            directory = pathlib.Path(td)
            fallback = directory / "manager.conf"
            runtime = directory / "thinstation.network"
            fallback.write_text("WAZUH_MANAGER=10.0.0.1\n")
            runtime.write_text("WAZUH_MANAGER=10.0.0.2\nUNRELATED=$(touch /tmp/wazuh-should-not-execute)\n")
            values = module.read_settings((fallback, runtime))
            self.assertEqual(module.check_manager(values["WAZUH_MANAGER"]), "10.0.0.2")

    def test_update_preserves_local_identity_and_other_xml(self):
        with tempfile.TemporaryDirectory() as td:
            directory = pathlib.Path(td)
            config = directory / "ossec.conf"
            identity = directory / "client.keys"
            identity.write_text("per-device-key")
            config.write_text("<ossec_config><client><server><address>old.example</address></server></client><localfile><location>/var/log/messages</location></localfile></ossec_config>")
            self.assertTrue(module.update_agent_config(config, "10.0.0.2"))
            self.assertFalse(module.update_agent_config(config, "10.0.0.2"))
            self.assertEqual(identity.read_text(), "per-device-key")
            self.assertIn("<location>/var/log/messages</location>", config.read_text())

    def test_hostname_comes_from_http_config(self):
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            file = root / "thinstation.network"
            file.write_text("NET_HOSTNAME=TC-001\\nWAZUH_MANAGER=192.0.2.50\\n")
            values = module.read_settings((file,))
            self.assertEqual(module.select_agent_name(values, "old-host"), "TC-001")

    def test_hostname_fallback_and_invalid_names(self):
        self.assertEqual(module.select_agent_name({"NET_HOSTNAME": "ts-*"}, "TC-002"), "TC-002")
        for name in ("localhost", "bad name", "none"):
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    module.select_agent_name({"NET_HOSTNAME": name}, "host")

    def test_bad_manager_rejected(self):
        for bad in ("", "bad;command", "http://server", "$(id)", "bad name"):
            with self.subTest(bad=bad):
                with self.assertRaises(ValueError):
                    module.check_manager(bad)


if __name__ == "__main__":
    unittest.main()
