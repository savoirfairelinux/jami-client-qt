"""Check that the deployed Windows client reaches its command-line parser."""

import ctypes
import os
import subprocess
import sys
from pathlib import Path

SEM_FAILCRITICALERRORS = 0x0001
SEM_NOGPFAULTERRORBOX = 0x0002


def main(executable):
    executable = Path(executable).resolve(strict=True)
    env = dict(os.environ,
               QT_QPA_PLATFORM="offscreen",
               QT_COMMAND_LINE_PARSER_NO_GUI_MESSAGE_BOXES="1")
    # Inherit error handling so loader failures do not open a modal dialog.
    kernel = ctypes.windll.kernel32
    previous_mode = kernel.GetErrorMode()
    kernel.SetErrorMode(previous_mode | SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX)
    try:
        result = subprocess.run([executable, "--version"], cwd=executable.parent,
                                env=env, timeout=30)
    except subprocess.TimeoutExpired:
        sys.exit(f"{executable.name} --version did not exit within 30 seconds.")
    finally:
        kernel.SetErrorMode(previous_mode)
    if result.returncode:
        sys.exit(f"{executable.name} --version failed (0x{result.returncode & 0xffffffff:08X}).")


if __name__ == "__main__":
    main(sys.argv[1])
