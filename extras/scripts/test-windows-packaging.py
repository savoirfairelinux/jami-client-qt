"""Packaging regression tests that do not run WiX or require its EULA."""

import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sys
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

    def test_pack_requires_explicit_acceptance(self):
        for value in ("", "true"):
            with self.subTest(env_value=value), \
                    patch.dict(os.environ, {"JAMI_ACCEPT_WIX_EULA": value}), \
                    patch.object(sys, "argv", ["build-windows.py", "pack", "--msi"]), \
                    patch.dict(self.script, {"get_vs_prop": self.fail}), \
                    contextlib.redirect_stderr(io.StringIO()) as stderr:
                with self.assertRaises(SystemExit) as exit_status:
                    self.script["main"]()
            self.assertNotEqual(exit_status.exception.code, 0)
            self.assertIn("--accept-wix-eula", stderr.getvalue())

    def test_pack_accepts_flag_or_explicit_environment(self):
        for flag, value in ((["--accept-wix-eula"], ""), ([], "1")):
            with self.subTest(flag=flag, env_value=value), \
                    patch.dict(os.environ, {"JAMI_ACCEPT_WIX_EULA": value}), \
                    patch.object(sys, "argv", ["build-windows.py", "pack", "--msi", *flag]):
                self.assertTrue(self.script["parse_args"]().accept_wix_eula)

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
                self.assertIn("-p:AcceptEula=wix7", cmd)
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

    def test_failed_qt_deploy_leaves_no_success_stamp(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            runtime = root / "x64" / "Release"
            runtime.mkdir(parents=True)
            fixtures = (
                "daemon/ringtones/01_AfroNigeria.opus",
                "extras/packaging/wix/qt.conf",
                "extras/packaging/wix/License.rtf",
                "resources/images/jami.ico",
            )
            for fixture in fixtures:
                path = root / fixture
                path.parent.mkdir(parents=True, exist_ok=True)
                path.touch()

            with patch.dict(os.environ), patch.dict(self.script, {
                "repo_root_dir": temp_dir,
                "daemon_dir": str(root / "daemon"),
                "get_vs_prop": lambda prop: temp_dir,
                "execute_cmd": lambda *args, **kwargs: 1,
            }):
                with self.assertRaisesRegex(SystemExit, "windeployqt"):
                    self.script["deploy_runtimes"](str(root / "qt"))

            self.assertFalse((runtime / ".deploy.stamp").exists())


if __name__ == "__main__":
    unittest.main()
