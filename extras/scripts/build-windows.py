#!/usr/bin/env python3
"""
Build, test, and package the project.

This script provides methods to build the project, build and run qml tests,
and package the project for Windows.

usage: build.py [-h] [-a ARCH] [-c CONFIG] [-t] [-i] [-v] {pack} ...

optional arguments:
  -a ARCH, --arch ARCH  Sets the build architecture
  -c CONFIG, --config CONFIG
                        Sets the build configuration type
  -t, --tests           Build and run tests
  -i, --init            Initialize submodules
  -v, --version         Show the version number and exit
  -s, --skip-build      Only do packaging or run tests, skip building

positional arguments:
  {pack}

usage: build.py pack [-h] [-s] (-m | -z)

mutually exclusive required arguments:
  -m, --msi         Build MSI installer
  -z, --zip         Build ZIP archive

examples:
1.  build.py --init pack --msi      # Build the application from scratch and
                                      an MSI installer
2.  build.py --init --tests         # Build the application from scratch and
                                      build and run tests
    build.py pack --zip             # Generate a ZIP archive of the application
                                      without building

"""

import sys
import os
import subprocess
import platform
import argparse
import multiprocessing


# Qt information
QT_VERSION = "6.2.3"
if sys.platform == "win32":
    QT_PATH = os.path.join("c:", os.sep, "Qt")
    QT_KIT_PATH = "msvc2019_64"
else:
    QT_PATH = ""
    QT_KIT_PATH = "clang_64"
qt_root_path = os.getenv("QT_ROOT_DIRECTORY", QT_PATH)

# Visual Studio helpers
VS_WHERE_PATH = ""
if sys.platform == "win32":
    VS_WHERE_PATH = os.path.join(
        os.environ["ProgramFiles(x86)"],
        "Microsoft Visual Studio",
        "Installer",
        "vswhere.exe",
    )
WIN_SDK_VERSION = "10.0.18362.0"

# Build/project environment information
is_jenkins = "JENKINS_URL" in os.environ
host_is_64bit = (False, True)[platform.machine().endswith("64")]
this_dir = os.path.dirname(os.path.realpath(__file__))
# the repo root is two levels up from this script
repo_root_dir = os.path.abspath(os.path.join(this_dir, os.pardir, os.pardir))
build_dir = os.path.join(repo_root_dir, "build")


def execute_cmd(cmd, with_shell=False, env_vars=None, cmd_dir=repo_root_dir):
    """Execute a command with subprocess."""
    proc = subprocess.Popen(
        cmd,
        shell=with_shell,
        stdout=sys.stdout,
        stderr=sys.stderr,
        env=env_vars,
        cwd=cmd_dir,
    )
    _, _ = proc.communicate()
    return proc.returncode


def get_latest_vs_version():
    """Find the latest visual c++ compiler tools version."""
    args = [
        "-latest",
        "-products *",
        "-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "-property installationVersion",
    ]
    cmd = [VS_WHERE_PATH] + args
    output = subprocess.check_output(" ".join(cmd)).decode("utf-8")
    if output:
        return output.splitlines()[0].split(".")[0]
    else:
        return


def find_latest_vs_dir():
    """Find the latest visual c++ compiler tools path."""
    args = [
        "-latest",
        "-products *",
        "-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "-property installationPath",
    ]
    cmd = [VS_WHERE_PATH] + args
    output = subprocess.check_output(
        " ".join(cmd)).decode("utf-8", errors="ignore")
    if output:
        return output.splitlines()[0]
    else:
        return


def find_ms_build():
    """Find the latest msbuild executable."""
    filename = "MSBuild.exe"
    vs_path = find_latest_vs_dir()
    if vs_path is None:
        return
    for root, _, files in os.walk(os.path.join(vs_path, "MSBuild")):
        if filename in files:
            return os.path.join(root, filename)


msbuild_cmd = find_ms_build()


def get_ms_build_args(arch, config_str, toolset=""):
    """Get an array of msbuild command args."""
    msbuild_args = [
        "/nologo",
        "/verbosity:minimal",
        "/maxcpucount:" + str(multiprocessing.cpu_count()),
        "/p:Platform=" + arch,
        "/p:Configuration=" + config_str,
        "/p:useenv=true",
    ]
    if toolset != "":
        msbuild_args.append("/p:PlatformToolset=" + toolset)
    return msbuild_args


def get_vs_env(arch="x64", _platform="", version=""):
    """Get the vcvarsall.bat command."""
    vs_env_cmd = get_vs_env_cmd(arch, _platform, version)
    if vs_env_cmd is None:
        return {}
    env_cmd = 'set path=%path:"=% && ' + vs_env_cmd + " && set"
    proc = subprocess.Popen(env_cmd, shell=True, stdout=subprocess.PIPE)
    stdout, _ = proc.communicate()
    out = stdout.decode("utf-8", errors="ignore").split("\r\n")[5: -1]
    return dict(s.split("=", 1) for s in out)


def get_vs_env_cmd(arch="x64", _platform="", version=""):
    """Get the vcvarsall.bat command."""
    vs_path = find_latest_vs_dir()
    if vs_path is None:
        return
    vc_env_init = [os.path.join(
        vs_path, "VC", "Auxiliary", "Build") + r'\"vcvarsall.bat']
    if _platform != "":
        args = [arch, _platform, version]
    else:
        args = [arch, version]
    if args:
        vc_env_init.extend(args)
    vc_env_init = 'call "' + " ".join(vc_env_init)
    return vc_env_init


def build_project(msbuild_args, proj, env_vars):
    """
    Use msbuild to build a project.

    Used specifically to build installer project and deps.
    """
    args = []
    args.extend(msbuild_args)
    args.append(proj)
    cmd = [msbuild_cmd]
    cmd.extend(args)
    if execute_cmd(cmd, True, env_vars):
        print("Failed when building ", proj)
        sys.exit(1)


def init_submodules():
    """Initialize any git submodules in the project."""
    print("Initializing submodules...")

    if execute_cmd(["git", "submodule", "update", "--init"], False):
        print("Submodule initialization error.")
    else:
        if execute_cmd(["git", "submodule", "update", "--recursive"], False):
            print("Submodule recursive checkout error.")
        else:
            print("Submodule recursive checkout finished.")


def build_deps():
    """Build the dependencies for the project."""
    print('Patching and building qrencode')
    apply_cmd = [
        'git',
        'apply',
        '--reject',
        '--ignore-whitespace',
        '--whitespace=fix'
    ]
    qrencode_dir = os.path.join(repo_root_dir, '3rdparty', 'qrencode-win32')
    patch_file = os.path.join(repo_root_dir, 'qrencode-win32.patch')
    apply_cmd.append(patch_file)
    if execute_cmd(apply_cmd, False, None, qrencode_dir):
        print("Couldn't patch qrencode-win32.")

    vs_env_vars = {}
    vs_env_vars.update(get_vs_env())

    msbuild_args = get_ms_build_args("x64", "Release-Lib")

    proj_path = os.path.join(
        qrencode_dir, "qrencode-win32", "vc8", "qrcodelib", "qrcodelib.vcxproj"
    )

    build_project(msbuild_args, proj_path, vs_env_vars)


def cmake_generate(options, env_vars, cmake_build_dir):
    """Generate the cmake project."""
    print("Generating cmake project...")

    # Pretty-print the options
    print("Options:")
    for option in options:
        print("    " + option)

    cmake_cmd = ["cmake", ".."]
    cmake_cmd.extend(options)
    if execute_cmd(cmake_cmd, False, env_vars, cmake_build_dir):
        print("CMake generation error.")
        return False
    return True


def cmake_build(config_str, env_vars, cmake_build_dir):
    """Use cmake to build the project."""
    print("Building cmake project...")

    cmake_cmd = ["cmake", "--build", ".", "--config", config_str, "--", "-m"]
    if execute_cmd(cmake_cmd, False, env_vars, cmake_build_dir):
        print("CMake build error.")
        return False
    return True


def build(config_str, qtver, tests):
    """Use cmake to build the project."""
    print("Building with Qt " + qtver)

    vs_env_vars = {}
    vs_env_vars.update(get_vs_env())

    # Get the Qt bin directory.
    qt_dir = os.path.join(qt_root_path, qtver, QT_KIT_PATH)

    # Get the daemon bin/include directories.
    daemon_dir = os.path.join(repo_root_dir, "daemon")
    daemon_bin_dir = os.path.join(
        daemon_dir, "build", "x64", "ReleaseLib_win32", "bin")

    # We need to update the minimum SDK version to be able to
    # build with system theme support
    cmake_options = [
        "-DWITH_DAEMON_SUBMODULE=ON",
        "-DCMAKE_PREFIX_PATH=" + qt_dir,
        "-DCMAKE_INSTALL_PREFIX=" + daemon_bin_dir,
        "-DLIBJAMI_INCLUDE_DIR=" + daemon_dir + "\\src\\jami",
        "-DCMAKE_SYSTEM_VERSION=" + WIN_SDK_VERSION,
        "-DCMAKE_BUILD_TYPE=" + config_str,
        "-DENABLE_TESTS=" + str(tests).lower(),
        "-DBETA=" + str((0, 1)[config_str == "Beta"]),
    ]

    # Make sure the build directory exists.
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    if not cmake_generate(cmake_options, vs_env_vars, build_dir):
        print("Cmake generate error")
        sys.exit(1)

    if not cmake_build(config_str, vs_env_vars, build_dir):
        print("Cmake build error")
        sys.exit(1)


def run_tests(config_str):
    """Run tests."""
    print("Running client tests")

    qt_dir = os.path.join(qt_root_path, QT_VERSION, QT_KIT_PATH)
    os.environ["PATH"] += os.pathsep + os.path.join(qt_dir, 'bin')
    os.environ["QT_QPA_PLATFORM"] = "offscreen"
    os.environ["QT_QUICK_BACKEND"] = "software"
    os.environ['QT_QPA_FONTDIR'] = os.path.join(
        repo_root_dir, 'resources', 'fonts')
    os.environ['QT_PLUGIN_PATH'] = os.path.join(qt_dir, 'plugins')
    os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = os.path.join(
        qt_dir, 'plugins', 'platforms')

    tests_dir = os.path.join(build_dir, "tests")
    if execute_cmd(["ctest", "-V", "-C", config_str],
                   False, None, tests_dir):
        print("Tests failed.")
        sys.exit(1)


def generate_msi(version):
    """Package MSI for Windows."""
    print("Generating MSI installer...")

    vs_env_vars = {}
    vs_env_vars.update(get_vs_env())
    msbuild_args = get_ms_build_args("x64", "Release")
    installer_dir = os.path.join(repo_root_dir, "JamiInstaller")
    installer_project = os.path.join(installer_dir, "JamiInstaller.wixproj")
    build_project(msbuild_args, installer_project, vs_env_vars)
    msi_dir = os.path.join(installer_dir, "bin", "Release", "en-us")
    msi_file_file = os.path.join(
        msi_dir, "jami.release.x64.msi")
    msi_version_file = os.path.join(
        msi_dir, "jami-" + version + ".msi")
    try:
        os.rename(msi_file_file, msi_version_file)
    except FileExistsError:
        os.remove(msi_version_file)
        os.rename(msi_file_file, msi_version_file)


def generate_zip(version):
    """Package archive for Windows."""
    print('Generating 7z archive...')

    # Generate 7z archive for Windows
    app_output_dir = os.path.join(repo_root_dir, 'x64', 'Release')
    app_files = os.path.join(app_output_dir, '*')

    # TODO: exclude Jami.PDB, .deploy.stamp, and vc_redist.x64.exe

    artifacts_dir = os.path.join(build_dir, 'artifacts')
    if not os.path.exists(artifacts_dir):
        os.makedirs(artifacts_dir)
    zip_file = os.path.join(artifacts_dir, 'jami-' +
                            version + '.7z')
    cmd = ['7z', 'a', '-t7z', '-r', zip_file, app_files]
    if execute_cmd(cmd, False):
        print('Generating 7z error.')


def get_version():
    """Get version from git tag."""
    version = ""
    cmd = ["git", "describe", "--tags", "--abbrev=0"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE)
    out, _ = proc.communicate()
    if out:
        version = out.decode("utf-8").strip()
    # transform slashes to dashes (if any)
    version = version.replace("/", "-")
    return version


def parse_args():
    """Parse arguments."""
    parser = argparse.ArgumentParser(description="Client build tool")
    subparsers = parser.add_subparsers(dest="subcommand")

    parser.add_argument(
        "-a", "--arch", default="x64", help="Sets the build architecture")
    parser.add_argument(
        "-t", "--tests", action="store_true", help="Build and run tests")
    parser.add_argument(
        '-v', '--version', action='store_true',
        help='Retrieve the current version')
    parser.add_argument(
        '-b', '--beta', action='store_true',
        help='Build Qt Client in Beta Config')
    parser.add_argument(
        '-q', '--qtver', default=QT_VERSION,
        help='Sets the version of Qmake')
    parser.add_argument(
        "-i", "--init", action="store_true", help="Initialize submodules")
    parser.add_argument(
        "-s",
        "--skip-build",
        action="store_true",
        default=False,
        help="Only do packaging or run tests, skip build step")

    pack_arg_parser = subparsers.add_parser("pack")
    pack_group = pack_arg_parser.add_mutually_exclusive_group(required=True)
    pack_group.add_argument(
        "-m", "--msi", action="store_true", help="Build MSI installer")
    pack_group.add_argument(
        "-z", "--zip", action="store_true", help="Build ZIP archive")

    return parser.parse_args()


def main():
    """Parse options and run the appropriate command."""
    if not host_is_64bit:
        print("These scripts will only run on a 64-bit system for now.")
        sys.exit(1)
    if sys.platform == "win32":
        vs_version = get_latest_vs_version()
        if vs_version is None or int(vs_version) < 15:
            print("Visual Studio 2017 or later is required.")
            sys.exit(1)

    # Quit if msbuild was not found
    if msbuild_cmd is None:
        print("msbuild.exe not found")
        sys.exit(1)

    parsed_args = parse_args()

    if parsed_args.version:
        print(get_version())
        sys.exit(0)

    if parsed_args.init:
        init_submodules()
        build_deps()
        sys.exit(0)

    config_str = ('Release', 'Beta')[parsed_args.beta]
    skip_build = parsed_args.skip_build

    if parsed_args.subcommand == "pack":
        if not skip_build:
            build(config_str, parsed_args.qtver, False)
        elif parsed_args.msi:
            generate_msi(get_version())
        elif parsed_args.zip:
            generate_zip(get_version())
    else:
        if not skip_build:
            build(config_str, parsed_args.qtver,
                  parsed_args.tests)
        if parsed_args.tests:
            run_tests(config_str)

    print("Done")


if __name__ == "__main__":
    main()
