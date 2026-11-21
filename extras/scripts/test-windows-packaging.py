"""Packaging regression tests that do not run WiX."""

import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


class WindowsPackagingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        script = Path(__file__).with_name("build-windows.py")
        spec = importlib.util.spec_from_file_location("build_windows", script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        cls.script = vars(module)

    def test_package_discovers_crt_and_replaces_versioned_msi(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            crt_dir = root / "VC Redist" / "x64" / "Microsoft.VC145.CRT"
            crt_dir.mkdir(parents=True)
            (crt_dir / "vcruntime140.dll").touch()
            msi_dir = root / "JamiInstaller" / "bin" / "Release" / "en-us"
            msi_dir.mkdir(parents=True)
            destination = msi_dir / "jami-1.2.3.msi"
            destination.write_bytes(b"old")

            def fake_build(cmd, *, env_vars):
                self.assertIn("--no-incremental", cmd)
                self.assertNotIn("-p:AcceptEula=wix7", cmd)
                self.assertIn(str(root / "JamiInstaller" / "JamiInstaller.wixproj"), cmd)
                self.assertEqual(Path(env_vars["VC_CRT_DIR"]), crt_dir)
                (msi_dir / "jami.release.x64.msi").write_bytes(b"new")
                return 0

            with patch.dict(os.environ, {"VC_CRT_DIR": ""}), \
                    patch.dict(self.script, {
                        "repo_root_dir": temp_dir,
                        "get_vs_env": lambda: {"VCToolsRedistDir": str(crt_dir.parent.parent)},
                        "execute_cmd": fake_build,
                    }), patch("shutil.which", return_value="dotnet"):
                self.script["generate_msi"]("1.2.3")
            self.assertEqual(destination.read_bytes(), b"new")


if __name__ == "__main__":
    unittest.main()
