#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build, test, and package the project.

This script provides methods to build the project, build and run qml tests,
and package the project for Windows.

usage: build.py [-q] [-h] [-a ARCH] [-c CONFIG] [-t] [-i] [-v] {pack} ...

optional arguments:
  -q, --qt PATH         Sets the Qt installation path
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
  -z, --zip         Build portable archive

examples:
1.  build.py --qt=C:/Qt/6.5.3/msvc2019_64  # Build the app using a specific Qt
2.  build.py --init pack --msi             # Build the app and an MSI installer
3.  build.py --init --tests                # Build the app and run tests
    build.py pack --zip --skip-build       # Generate a 7z archive of the app
                                             without building

"""

import sys
import os
import subprocess
import platform
import argparse
import multiprocessing
import shutil
import time


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

def get_latest_toolset_version():
    """Get the latest toolset version."""
    # Get the visual studio version. Use only the major version number.
    # Then: toolset = 2022 ? "v143" : 2019 ? "v142" : 2017 ? "v141" : "v140"
    vs_ver = get_vs_prop("installationVersion")
    if vs_ver is None:
        return None
    vs_ver = int(vs_ver.split(".")[0])
    if vs_ver == 17:
        return "v143"
    elif vs_ver == 16:
        return "v142"
    else:
        return "v141"

def find_latest_qt_path():
    """Find the latest Qt installation path."""
    # Start with the default install path.
    qt_base_path = os.path.join("c:", os.sep, "Qt")
    # There should be folders named with SEMVER numbers under it.
    # Find the highest version number with an alphabetical sort dirname.
    qt_version_dirs = sorted(os.listdir(qt_base_path), reverse=True)
    # Filter out any non-numeric version numbers.
    qt_version_dirs = [d for d in qt_version_dirs if d[0].isnumeric()]
    # If there are no version numbers, return None.
    if len(qt_version_dirs) == 0:
        return None
    # The latest version should be the last item in the list.
    return os.path.join(qt_base_path, qt_version_dirs[0], 'msvc2019_64')


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


def get_vs_prop(prop):
    """Get a visual studio property."""
    args = [
        "-latest",
        "-products *",
        "-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "-property " + prop,
    ]
    cmd = [VS_WHERE_PATH] + args
    output = subprocess.check_output(" ".join(cmd)).decode("utf-8")
    if output:
        return output.splitlines()[0]
    else:
        return None


def find_ms_build():
    """Find the latest msbuild executable."""
    filename = "MSBuild.exe"
    vs_path = get_vs_prop("installationPath")
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
    env_cmd = f'set path=%path:"=% && {vs_env_cmd} && set'
    proc = subprocess.Popen(env_cmd, shell=True, stdout=subprocess.PIPE)
    stdout, _ = proc.communicate()
    out = stdout.decode("utf-8", errors="ignore").split("\r\n")[5: -1]
    return dict(s.split("=", 1) for s in out)


def get_vs_env_cmd(arch="x64", _platform="", version=""):
    """Get the vcvarsall.bat command."""
    vs_path = get_vs_prop("installationPath")
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

    # Init the client submodules for Windows other than the daemon.
    submodules = [
        "3rdparty/qrencode-win32",
        "3rdparty/SortFilterProxyModel",
        "3rdparty/md4c",
        "3rdparty/tidy-html5",
    ]
    if execute_cmd(["git", "submodule", "update", "--init" ] + submodules,
                   False):
        print("Submodule initialization error.")
        sys.exit(1)


def build_deps():
    """Build the dependencies for the project."""
    print('Building qrencode')
    qrencode_dir = os.path.join(repo_root_dir, '3rdparty', 'qrencode-win32')
    vs_env_vars = {}
    vs_env_vars.update(get_vs_env())
    toolset = get_latest_toolset_version()
    print(f'Using toolset {toolset}')
    msbuild_args = get_ms_build_args("x64", "Release-Lib", toolset)
    proj_path = os.path.join(
        qrencode_dir, "qrencode-win32", "vc15", "qrcodelib", "qrcodelib.vcxproj"
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


def build(config_str, qt_dir, tests):
    """Use cmake to build the project."""
    print("Building with Qt at " + qt_dir)

    vs_env_vars = {}
    vs_env_vars.update(get_vs_env())

    # Get the daemon bin/include directories.
    daemon_dir = os.path.join(repo_root_dir, "daemon")
    daemon_bin_dir = os.path.join(daemon_dir, "build", "lib")

    # We need to update the minimum SDK version to be able to
    # build with system theme support
    cmake_options = [
        "-DJAMICORE_AS_SUBDIR=ON",
        "-DCMAKE_PREFIX_PATH=" + qt_dir,
        "-DCMAKE_MSVCIDE_RUN_PATH=" + qt_dir + "\\bin",
        "-DCMAKE_INSTALL_PREFIX=" + os.getcwd(),
        "-DCMAKE_SYSTEM_VERSION=" + WIN_SDK_VERSION,
        "-DCMAKE_BUILD_TYPE=" + "Release",
        "-DENABLE_TESTS=" + str(tests).lower(),
        "-DBETA=" + str((0, 1)[config_str == "Beta"]),
    ]

    # Make sure the build directory exists.
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    if not cmake_generate(cmake_options, vs_env_vars, build_dir):
        print("Cmake generate error")
        sys.exit(1)

    if not cmake_build("Release", vs_env_vars, build_dir):
        print("Cmake build error")
        sys.exit(1)


def deploy_runtimes(config_str, qt_dir):
    """Deploy the dependencies to the runtime directory."""
    print("Deploying runtime dependencies")

    runtime_dir = os.path.join(repo_root_dir, "x64", config_str)
    stamp_file = os.path.join(runtime_dir, ".deploy.stamp")
    if os.path.exists(stamp_file):
        return

    daemon_dir = os.path.join(repo_root_dir, "daemon")
    ringtone_dir = os.path.join(daemon_dir, "ringtones")
    packaging_dir = os.path.join(repo_root_dir, "extras", "packaging")

    def install_file(src, rel_path):
        shutil.copy(os.path.join(rel_path, src), runtime_dir)

    print("Copying libjami dependencies")
    install_file("contrib/build/openssl/libcrypto-1_1-x64.dll", daemon_dir)
    install_file("contrib/build/openssl/libssl-1_1-x64.dll", daemon_dir)
    # Ringtone files (ul,ogg,wav,opus files in the daemon ringtone dir).

    print("Copying ringtones")
    ringtone_dir = os.path.join(daemon_dir, "ringtones")
    ringtone_files = [f for f in os.listdir(ringtone_dir) if f.endswith(
        (".ul", ".ogg", ".wav", ".opus"))]
    ringtone_files = [os.path.join(ringtone_dir, f) for f in ringtone_files]
    default_ringtone = os.path.join(ringtone_dir, "default.opus")
    ringtone_files.remove(default_ringtone)
    ringtone_dir_out = os.path.join(runtime_dir, "ringtones")
    if os.path.exists(ringtone_dir_out):
        shutil.rmtree(ringtone_dir_out)
    os.makedirs(ringtone_dir_out, exist_ok=True)
    for ringtone in ringtone_files:
        shutil.copy(ringtone, os.path.join(runtime_dir, "ringtones"))
    # Create a hard link to the default ringtone (Windows).
    os.link(os.path.join(runtime_dir, "ringtones", "01_AfroNigeria.opus"),
            os.path.join(runtime_dir, "ringtones", "default.opus"))

    print("Copying misc. client configuration files")
    install_file("wix/qt.conf", packaging_dir)
    install_file("wix/License.rtf", packaging_dir)
    install_file("resources/images/jami.ico", repo_root_dir)

    # windeployqt
    print("Running windeployqt (this may take a while)...")
    win_deploy_qt = os.path.join(qt_dir, "bin", "windeployqt.exe")
    qml_src_dir = os.path.join(repo_root_dir, "src", "app")
    installation_dir = get_vs_prop("installationPath")
    if not installation_dir:
        print("Visual Studio not found. Please install Visual Studio 2017 or "
              "later.")
        sys.exit(1)
    os.environ["VCINSTALLDIR"] = os.path.join(installation_dir, "VC")
    executable = os.path.join(runtime_dir, "Jami.exe")
    execute_cmd([win_deploy_qt, "--verbose", "1", "--no-compiler-runtime",
                 "--qmldir", qml_src_dir, "--release", executable],
                False, cmd_dir=runtime_dir)

    with open(stamp_file, "w", encoding="utf-8") as file:
        # Write the current time to the file.
        file.write(str(time.time()))


def run_tests(config_str, qt_dir):
    """Run tests."""
    print("Running client tests")

    os.environ["PATH"] += os.pathsep + os.path.join(qt_dir, 'bin')
    daemon_dir = os.path.join(repo_root_dir, "daemon")
    os.environ["PATH"] += os.pathsep + \
        os.path.join(daemon_dir, "contrib", "build", "openssl")
    os.environ["QT_QPA_PLATFORM"] = "offscreen"
    os.environ["QT_QUICK_BACKEND"] = "software"
    os.environ['QT_QPA_FONTDIR'] = os.path.join(
        repo_root_dir, 'resources', 'fonts')
    os.environ['QT_PLUGIN_PATH'] = os.path.join(qt_dir, 'plugins')
    os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = os.path.join(
        qt_dir, 'plugins', 'platforms')
    os.environ['QTWEBENGINEPROCESS_PATH'] = os.path.join(
        qt_dir, 'bin', 'QtWebEngineProcess.exe')
    os.environ["QML2_IMPORT_PATH"] = os.path.join(qt_dir, "qml")

    cmd = ["ctest", "-V", "-C", config_str]
    # On Windows, when running on a jenkins slave, the QML tests don't output
    # anything to stdout/stderr. Workaround by outputting to a file and then
    # printing the contents of the file.
    if os.environ.get("JENKINS_URL"):
        cmd += ["--output-log", "test.log", "--quiet"]
    tests_dir = os.path.join(build_dir, "tests")
    exit_code = execute_cmd(cmd, False, None, tests_dir)
    # Print the contents of the log file.
    if os.environ.get("JENKINS_URL"):
        with open(os.path.join(tests_dir, "test.log"), "r") as file:
            print(file.read())
    sys.exit(exit_code)


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

    # TODO: exclude Jami.PDB, .deploy.stamp

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

    # The Qt install path is not required and will be searched for if not
    # specified. In that case, the latest version of Qt will be used.
    parser.add_argument('-q', '--qt', default=None,
                        help='Sets the Qt root path')
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
        "-i", "--init", action="store_true", help="Initialize submodules")
    parser.add_argument(
        '-sd',
        '--skip-deploy',
        action='store_true',
        default=False,
        help='Force skip deployment of runtime files needed for packaging')
    parser.add_argument(
        "-sb",
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
        vs_version = get_vs_prop("installationVersion")
        if vs_version is None:
            print("Visual Studio version not found.")
            sys.exit(1)
        vs_version = vs_version.split(".")[0]
        if vs_version is None or int(vs_version) < 15:
            print("Visual Studio 2017 or later is required.")
            sys.exit(1)

    # Quit if msbuild was not found
    if msbuild_cmd is None:
        print("msbuild.exe not found")
        sys.exit(1)

    parsed_args = parse_args()

    if not parsed_args.qt:
        parsed_args.qt = find_latest_qt_path()
        if not parsed_args.qt:
            print("Qt not found. Please specify the path to Qt.")
            sys.exit(1)

    if parsed_args.version:
        print(get_version())
        sys.exit(0)

    if parsed_args.init:
        init_submodules()
        build_deps()
        sys.exit(0)

    config_str = ('Release', 'Beta')[parsed_args.beta]

    def do_build(do_tests):
        if not parsed_args.skip_build:
            build(config_str, parsed_args.qt, do_tests)
        if not parsed_args.skip_deploy:
            deploy_runtimes(config_str, parsed_args.qt)

    if parsed_args.subcommand == "pack":
        do_build(False)
        if parsed_args.msi:
            generate_msi(get_version())
        elif parsed_args.zip:
            generate_zip(get_version())
    else:
        do_build(parsed_args.tests)
        if parsed_args.tests:
            run_tests(config_str, parsed_args.qt)

    print("Done")


if __name__ == "__main__":
    main()
