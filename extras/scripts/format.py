#!/usr/bin/env python3
"""
Clang format C/C++ source files with clang-format.
Also optionally installs a pre-commit hook to run this script.

Usage:
    format.py [-a | --all] [-i | --install PATH]

    -a | --all
        Format all files instead of only committed ones

    -i | --install PATH
        Install a pre-commit hook to run this script in PATH
"""

import os
import sys
import subprocess
import argparse
import shutil

CFVERSION = "9"
CLANGFORMAT = ""


def command_exists(cmd):
    """ Check if a command exists """
    return shutil.which(cmd) is not None


def clang_format_file(filename):
    """ Format a file using clang-format """
    if os.path.isfile(filename):
        subprocess.call([CLANGFORMAT, "-i", "-style=file", filename])


def clang_format_files(files):
    """ Format a list of files """
    for filename in files:
        print(f"Formatting: {filename}", end='\r')
        clang_format_file(filename)


def exit_if_no_files():
    """ Exit if no files to format """
    print("No files to format")
    sys.exit(0)


def install_hook(hooks_path):
    """ Install a pre-commit hook to run this script """
    if not os.path.isdir(hooks_path):
        print(f"{hooks_path} path does not exist")
        sys.exit(1)
    print(f"Installing pre-commit hook in {hooks_path}")
    with open(os.path.join(hooks_path, "pre-commit"),
              "w", encoding="utf-8") as file:
        file.write(os.path.realpath(sys.argv[0]))
    os.chmod(os.path.join(hooks_path, "pre-commit"), 0o755)


def get_files(file_types, recursive=True, committed_only=False):
    """
    Get a list of files in the src directory [and subdirectories].
    Filters by file types and whether the file is committed.
    """
    file_list = []
    committed_files = []
    if committed_only:
        committed_files = subprocess.check_output(
            "git diff-index --cached --name-only HEAD",
            shell=True).decode().strip().split('\n')
    for dirpath, _, filenames in os.walk('src'):
        for filename in filenames:
            file_path = os.path.join(dirpath, filename)
            if file_types and not any(file_path.endswith(file_type)
                                      for file_type in file_types):
                continue  # Skip files that don't match any file types.
            if committed_only:
                if file_path not in committed_files:
                    continue  # Skip uncommitted files.
            file_list.append(file_path)
        if not recursive:
            break  # Stop searching if not recursive.
    return file_list


def main():
    """Check if clang-format is installed, and format files."""
    global CLANGFORMAT  # pylint: disable=global-statement
    parser = argparse.ArgumentParser(
        description="Format source filess with a clang-format")
    parser.add_argument("-a", "--all", action="store_true",
                        help="format all files instead of only committed ones")
    parser.add_argument("-i", "--install", metavar="PATH",
                        help="install a pre-commit hook to run this script")
    args = parser.parse_args()

    if not command_exists("clang-format-" + CFVERSION):
        if not command_exists("clang-format"):
            print("Required version of clang-format not found")
            sys.exit(1)
        else:
            CLANGFORMAT = "clang-format"
    else:
        CLANGFORMAT = "clang-format-" + CFVERSION

    if args.install:
        install_hook(args.install)
        sys.exit(0)

    if args.all:
        print("Formatting all files...")
        # Find all files in the recursively in the current directory.
        clang_format_files(get_files((".cpp", ".cxx", ".cc", ".h", ".hpp"),
                                     committed_only=False))
    else:
        files = get_files((".cpp", ".cxx", ".cc", ".h", ".hpp"),
                          committed_only=True)
        if not files:
            exit_if_no_files()
        print("Formatting committed source files...")
        clang_format_files(files)


if __name__ == "__main__":
    main()
