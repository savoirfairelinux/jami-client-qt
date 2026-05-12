#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build, test, and package the project.

This script provides methods to build the project, build and run qml tests,
and package the project for Windows.

usage: build.py [-q] [-h] [-a ARCH] [-c CONFIG] [-t] [-i] [-v] {pack} ...

optional arguments:
  -q, --qt PATH             Sets the Qt installation path
  -a ARCH, --arch ARCH      Sets the build architecture
  -c CONFIG, --config CONFIG
                            Sets the build configuration type
  -t, --tests               Build and run tests
  -i, --init                Initialize submodules
  -v, --version             Show the version number and exit
  -s, --skip-build          Only do packaging or run tests, skip building
  --enable-crash-reports    Enable crash reports

positional arguments:
  {pack}

usage: build.py pack [-h] [-s] (-m | -z)

mutually exclusive required arguments:
  -m, --msi         Build MSI installer
  -z, --zip         Build portable archive

examples:
1.  build.py --qt=C:/Qt/6.10.3/msvc2022_64 # Build the app using a specific Qt
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
import json
import hashlib
import multiprocessing
import shutil
import time
from xml.sax.saxutils import escape as xml_escape


# Visual Studio helpers
VS_WHERE_PATH = ""
if sys.platform == "win32":
    VS_WHERE_PATH = os.path.join(
        os.environ["ProgramFiles(x86)"],
        "Microsoft Visual Studio",
        "Installer",
        "vswhere.exe",
    )
WIN_SDK_VERSION = "10.0.26100.0"
WIX_VERSION = "7.0.0"
WIX_EULA_ID = "wix7"
WIX_EXTENSIONS = [
    "WixToolset.UI.wixext",
    "WixToolset.Util.wixext",
]

# Build/project environment information
is_jenkins = "JENKINS_URL" in os.environ
host_is_64bit = (False, True)[platform.machine().endswith("64")]
this_dir = os.path.dirname(os.path.realpath(__file__))
# the repo root is two levels up from this script
repo_root_dir = os.path.abspath(os.path.join(this_dir, os.pardir, os.pardir))
build_dir = os.path.join(repo_root_dir, "build")

VS_GENERATORS = {
    18: "Visual Studio 18 2026",
    17: "Visual Studio 17 2022",
}
VS_TOOLSETS = {
    18: "v145",
    17: "v143",
}
selected_vs_installation = None


def get_installed_vs_instances():
    """Return installed Visual Studio instances with C++ tools."""
    args = [
        "-prerelease",
        "-products",
        "*",
        "-requires",
        "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "-format",
        "json",
    ]
    try:
        output = subprocess.check_output([VS_WHERE_PATH] + args).decode("utf-8")
    except (OSError, subprocess.CalledProcessError):
        return []
    if not output:
        return []
    return json.loads(output)


def get_vs_major_from_instance(instance):
    """Return the Visual Studio major version for an instance."""
    version = instance.get("installationVersion", "")
    if not version:
        return None
    return int(version.split(".")[0])


def get_supported_cmake_generators():
    """Return the generators supported by the cmake on PATH."""
    try:
        output = subprocess.check_output(["cmake", "--help"], stderr=subprocess.STDOUT).decode("utf-8", errors="ignore")
    except (OSError, subprocess.CalledProcessError):
        return None
    return output


def get_selected_vs_installation():
    """Select the newest installed Visual Studio supported by local CMake."""
    global selected_vs_installation
    if selected_vs_installation is not None:
        return selected_vs_installation

    instances = get_installed_vs_instances()
    if not instances:
        return None
    instances = sorted(
        instances,
        key=lambda instance: instance.get("installationVersion", ""),
        reverse=True,
    )
    cmake_generators = get_supported_cmake_generators()
    for instance in instances:
        major_version = get_vs_major_from_instance(instance)
        generator = VS_GENERATORS.get(major_version)
        if generator is None:
            continue
        if cmake_generators is None or generator in cmake_generators:
            selected_vs_installation = instance
            return selected_vs_installation
    selected_vs_installation = instances[0]
    return selected_vs_installation


def get_vs_major_version():
    """Get the installed Visual Studio major version."""
    vs_ver = get_selected_vs_installation()
    if vs_ver is None:
        return None
    return get_vs_major_from_instance(vs_ver)


def get_latest_toolset_version():
    """Get the latest toolset version."""
    vs_ver = get_vs_major_version()
    if vs_ver is None:
        return None
    return VS_TOOLSETS.get(vs_ver)


def get_cmake_generator():
    """Get the CMake Visual Studio generator for the installed toolchain."""
    vs_ver = get_vs_major_version()
    if vs_ver in VS_GENERATORS:
        return VS_GENERATORS[vs_ver]
    print("Unsupported Visual Studio version for CMake generation: " + str(vs_ver))
    return None

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
    qt_arch_dirs = ["msvc2022_64"]
    for qt_version_dir in qt_version_dirs:
        for qt_arch_dir in qt_arch_dirs:
            qt_path = os.path.join(qt_base_path, qt_version_dir, qt_arch_dir)
            if os.path.isdir(qt_path):
                return qt_path
    return os.path.join(qt_base_path, qt_version_dirs[0], qt_arch_dirs[0])


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
    instance = get_selected_vs_installation()
    if instance is None:
        return None
    return instance.get(prop)


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
        "3rdparty/SortFilterProxyModel",
        "3rdparty/md4c",
        "3rdparty/tidy-html5",
        "3rdparty/zxing-cpp",
        "3rdparty/hunspell",
    ]
    if execute_cmd(["git", "submodule", "update", "--init" ] + submodules,
                   False):
        print("Submodule initialization error.")
        sys.exit(1)


def cmake_generate(options, env_vars, cmake_build_dir):
    """Generate the cmake project."""
    print("Generating cmake project...")

    # Pretty-print the options
    print("Options:")
    for option in options:
        print("    " + option)

    cmake_generator = get_cmake_generator()
    if cmake_generator is None:
        return False
    cmake_cmd = ["cmake", "..", "-G", cmake_generator]
    cmake_cmd.extend(options)
    if execute_cmd(cmake_cmd, False, env_vars, cmake_build_dir):
        print("CMake generation error.")
        return False
    return True


def cmake_build(config_str, env_vars, cmake_build_dir):
    """Use cmake to build the project."""
    print("Building cmake project...")

    msbuild_max_cpu = os.environ.get("JAMI_MSBUILD_MAX_CPU", "")
    msbuild_parallel_arg = "-m"
    if msbuild_max_cpu:
        msbuild_parallel_arg = "-m:" + msbuild_max_cpu
    cmake_cmd = ["cmake", "--build", ".", "--config", config_str, "--", msbuild_parallel_arg]
    if execute_cmd(cmake_cmd, False, env_vars, cmake_build_dir):
        print("CMake build error.")
        return False
    return True


def build(config_str, qt_dir, tests, build_version, enable_crash_reports, crash_report_url=None):
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
        "-DBUILD_CONTRIB=ON",
        "-DCMAKE_PREFIX_PATH=" + qt_dir,
        "-DCMAKE_MSVCIDE_RUN_PATH=" + qt_dir + "\\bin",
        "-DCMAKE_INSTALL_PREFIX=" + os.getcwd(),
        "-DCMAKE_BUILD_TYPE=" + "Release",
        "-DBUILD_TESTING=" + str(tests).lower(),
        "-DBETA=" + str((0, 1)[config_str == "Beta"]),
    ]

    if enable_crash_reports:
        cmake_options.append("-DENABLE_CRASHREPORTS=ON")
        if crash_report_url:
            cmake_options.append(f"-DCRASH_REPORT_URL={crash_report_url}")
    else:
        cmake_options.append("-DENABLE_CRASHREPORTS=OFF")

    if build_version:
        cmake_options.append("-DBUILD_VERSION=" + build_version)

    # Make sure the build directory exists.
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    if not cmake_generate(cmake_options, vs_env_vars, build_dir):
        print("Cmake generate error")
        sys.exit(1)

    if not cmake_build("Release", vs_env_vars, build_dir):
        print("Cmake build error")
        sys.exit(1)


def deploy_runtimes(qt_dir):
    """Deploy the dependencies to the runtime directory."""
    print("Deploying runtime dependencies")

    runtime_dir = os.path.join(repo_root_dir, "x64", "Release")
    stamp_file = os.path.join(runtime_dir, ".deploy.stamp")
    executable = os.path.join(runtime_dir, "Jami.exe")
    qt_core_dll = os.path.join(runtime_dir, "Qt6Core.dll")
    if os.path.exists(stamp_file) and os.path.exists(executable) and os.path.exists(qt_core_dll):
        return
    if os.path.exists(stamp_file):
        os.remove(stamp_file)

    daemon_dir = os.path.join(repo_root_dir, "daemon")
    ringtone_dir = os.path.join(daemon_dir, "ringtones")
    packaging_dir = os.path.join(repo_root_dir, "extras", "packaging")

    def install_file(src, rel_path):
        shutil.copy(os.path.join(rel_path, src), runtime_dir)

    print("Copying libjami dependencies")
    install_file("contrib/build/openssl/libcrypto-3-x64.dll", daemon_dir)
    install_file("contrib/build/openssl/libssl-3-x64.dll", daemon_dir)
    # Ringtone files (ul,ogg,wav,opus files in the daemon ringtone dir).

    print("Copying ringtones")
    ringtone_dir = os.path.join(daemon_dir, "ringtones")
    ringtone_files = [f for f in os.listdir(ringtone_dir) if f.endswith(
        (".ul", ".ogg", ".wav", ".opus"))]
    ringtone_files = [os.path.join(ringtone_dir, f) for f in ringtone_files]
    default_ringtone = os.path.join(ringtone_dir, "default.opus")
    if default_ringtone in ringtone_files:
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
    win_deploy_qt = os.path.join(qt_dir, "bin", "windeployqt.exe")
    print(f"Running windeployqt ({win_deploy_qt}) (this may take a while)...")
    qml_src_dir = os.path.join(repo_root_dir, "src", "app")
    installation_dir = get_vs_prop("installationPath")
    if not installation_dir:
        print("Visual Studio not found. Please install Visual Studio 2017 or "
              "later.")
        sys.exit(1)
    os.environ["VCINSTALLDIR"] = os.path.join(installation_dir, "VC")
    if execute_cmd([win_deploy_qt, "--verbose", "1", "--no-compiler-runtime",
                    "--qmldir", qml_src_dir, "--release", executable],
                   False, cmd_dir=runtime_dir):
        print("windeployqt failed.")
        sys.exit(1)
    if not os.path.exists(qt_core_dll):
        print("windeployqt did not deploy Qt6Core.dll.")
        sys.exit(1)

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


def env_get(env_vars, name):
    """Case-insensitive environment lookup."""
    for key, value in env_vars.items():
        if key.upper() == name.upper():
            return value
    return None


def find_vc_crt_dir(env_vars):
    """Find the MSVC CRT redist directory for the active toolchain."""
    for env_name in ("VC_CRT_Dir", "VC_CRT_REDIST_DIR"):
        value = env_get(env_vars, env_name)
        if value and os.path.isdir(value):
            return value

    redist_dir = env_get(env_vars, "VCToolsRedistDir")
    if redist_dir:
        arch_dir = os.path.join(redist_dir, "x64")
        if os.path.isdir(arch_dir):
            for name in sorted(os.listdir(arch_dir), reverse=True):
                candidate = os.path.join(arch_dir, name)
                if name.startswith("Microsoft.VC") and name.endswith(".CRT") and os.path.isdir(candidate):
                    return candidate

    return None


def find_wix():
    """Find the WiX command-line tool."""
    wix_cmd = shutil.which("wix")
    if wix_cmd:
        return wix_cmd

    user_profile = os.environ.get("USERPROFILE")
    if user_profile:
        wix_cmd = os.path.join(user_profile, ".dotnet", "tools", "wix.exe")
        if os.path.isfile(wix_cmd):
            return wix_cmd

    return None


def get_wix_eula_args():
    """Return WiX 7 EULA arguments when explicitly enabled."""
    accept = os.environ.get("WIX_ACCEPT_EULA", "").strip().lower()
    if accept in ("1", "true", "yes", "on", WIX_EULA_ID):
        return ["--acceptEula", WIX_EULA_ID]
    return []


def wix_id(prefix, value):
    """Create a stable WiX identifier from a relative path."""
    digest = hashlib.sha1(value.replace(os.sep, "/").encode("utf-8")).hexdigest()
    return prefix + digest[:32]


def write_wix_component_group(output_file, group_id, root_dir, exclude_file=None):
    """Generate WiX component authoring for a directory tree."""
    root_dir = os.path.abspath(root_dir)
    files = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        dirnames.sort()
        for filename in sorted(filenames):
            path = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(path, root_dir)
            if exclude_file and exclude_file(rel_path):
                continue
            files.append(rel_path)

    tree = {"dirs": {}, "files": []}
    for rel_path in files:
        parts = rel_path.split(os.sep)
        node = tree
        for directory_name in parts[:-1]:
            node = node["dirs"].setdefault(directory_name, {"dirs": {}, "files": []})
        node["files"].append(rel_path)

    component_ids = []
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">',
        '  <Fragment>',
        '    <DirectoryRef Id="APPLICATIONFOLDER">',
    ]

    def emit_node(node, indent, rel_dir=""):
        for rel_path in node["files"]:
            source = xml_escape(os.path.join(root_dir, rel_path))
            component_id = wix_id("cmp", group_id + ":" + rel_path)
            file_id = wix_id("fil", group_id + ":" + rel_path)
            component_ids.append(component_id)
            lines.extend([
                f'{indent}<Component Id="{component_id}" Bitness="always64">',
                f'{indent}  <File Id="{file_id}" Source="{source}" KeyPath="yes" />',
                f'{indent}</Component>',
            ])

        for directory_name in sorted(node["dirs"]):
            child_rel_dir = os.path.join(rel_dir, directory_name) if rel_dir else directory_name
            directory_id = wix_id("dir", group_id + ":" + child_rel_dir)
            lines.append(f'{indent}<Directory Id="{directory_id}" Name="{xml_escape(directory_name)}">')
            emit_node(node["dirs"][directory_name], indent + "  ", child_rel_dir)
            lines.append(f'{indent}</Directory>')

    emit_node(tree, "      ")
    lines.extend([
        '    </DirectoryRef>',
        '  </Fragment>',
        '  <Fragment>',
        f'    <ComponentGroup Id="{group_id}">',
    ])
    for component_id in component_ids:
        lines.append(f'      <ComponentRef Id="{component_id}" />')
    lines.extend([
        '    </ComponentGroup>',
        '  </Fragment>',
        '</Wix>',
        '',
    ])

    with open(output_file, "w", encoding="utf-8", newline="\n") as file:
        file.write("\n".join(lines))


def generate_msi(version):
    """Package MSI for Windows."""
    print("Generating MSI installer...")

    vs_env_vars = {}
    vs_env_vars.update(get_vs_env())
    installer_dir = os.path.join(repo_root_dir, "JamiInstaller")
    release_dir = os.path.join(repo_root_dir, "x64", "Release")
    crt_dir = find_vc_crt_dir(vs_env_vars)
    wix_cmd = find_wix()

    if not os.path.isfile(os.path.join(release_dir, "Jami.exe")):
        print("Jami.exe was not found in " + release_dir)
        sys.exit(1)
    if crt_dir is None:
        print("MSVC CRT redist directory not found.")
        sys.exit(1)
    if wix_cmd is None:
        print("WiX 7 was not found. Install it with: dotnet tool install --global wix --version " + WIX_VERSION)
        sys.exit(1)

    def exclude_app_file(rel_path):
        filename = os.path.basename(rel_path).lower()
        return filename == "jami.exe" or filename.endswith(".pdb")

    write_wix_component_group(
        os.path.join(installer_dir, "AppComponents.wxs"),
        "AppHeatGenerated",
        release_dir,
        exclude_app_file)
    write_wix_component_group(
        os.path.join(installer_dir, "CrtComponents.wxs"),
        "CrtHeatGenerated",
        crt_dir)

    msi_dir = os.path.join(installer_dir, "bin", "Release", "en-us")
    os.makedirs(msi_dir, exist_ok=True)
    msi_file_file = os.path.join(
        msi_dir, "jami.release.x64.msi")
    msi_version_file = os.path.join(
        msi_dir, "jami-" + version + ".msi")
    for output_file in (msi_file_file, msi_version_file):
        if os.path.exists(output_file):
            os.remove(output_file)

    wix_build_cmd = [
        wix_cmd,
        "build",
    ] + get_wix_eula_args()
    for wix_extension in WIX_EXTENSIONS:
        wix_build_cmd.extend(["-ext", wix_extension])
    wix_build_cmd.extend([
        "Product.wxs",
        "AppComponents.wxs",
        "CrtComponents.wxs",
        "-loc", "Localization.wxl",
        "-culture", "en-us",
        "-arch", "x64",
        "-intermediatefolder", os.path.join(installer_dir, "obj", "Release"),
        "-out", msi_file_file,
    ])
    if execute_cmd(wix_build_cmd, False, vs_env_vars, installer_dir):
        print("WiX build error.")
        sys.exit(1)

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
        "--build-version", help="Sets the build version string used for defining app build version")
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
        '--skip-deploy',
        action='store_true',
        default=False,
        help='Force skip deployment of runtime files needed for packaging')
    parser.add_argument(
        "--skip-build",
        action="store_true",
        default=False,
        help="Only do packaging or run tests, skip build step")
    parser.add_argument(
        '--enable-crash-reports',
        action='store_true',
        default=False,
        help='Enable crash reporting')
    parser.add_argument(
        '--crash-report-url',
        help='Override the crash report submission URL',
        default=None)

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
        sys.exit(0)

    config_str = ('Release', 'Beta')[parsed_args.beta]

    def do_build(do_tests):
        if not parsed_args.skip_build:
            build(config_str, parsed_args.qt, do_tests,
                  parsed_args.build_version,
                  parsed_args.enable_crash_reports,
                  parsed_args.crash_report_url)
        if not parsed_args.skip_deploy:
            deploy_runtimes(parsed_args.qt)

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
