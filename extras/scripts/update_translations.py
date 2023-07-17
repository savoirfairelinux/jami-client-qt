#!/usr/bin/python
import os
import argparse
import subprocess
import sys

def update_translations(qt_path):
    """Update translations using lupdate"""
    client_dir = os.getcwd()
    lupdate = os.path.join(qt_path, "bin", "lupdate.exe")

    # Find all .ts files
    ts_file_names = []
    for root, dirs, files in os.walk(os.path.join(client_dir, "translations")):
        for file in files:
            if file.endswith(".ts"):
                ts_file_names.append(os.path.join(root, file))

    # Run lupdate
    result = subprocess.run([lupdate,
                             os.path.join(client_dir, "src"),
                             "-ts"] + ts_file_names + ["-no-obsolete"],
                             check=True)
    if result.returncode != 0:
        print("lupdate failed")
        sys.exit(result.returncode)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Update translations using lupdate")
    parser.add_argument("--qt", help="Path to the Qt installation directory")
    args = parser.parse_args()
    update_translations(args.qt)