#!/usr/bin/env python3
# build.py --- Convenience script for building and running Jami

# Copyright (C) 2016-2024 Savoir-faire Linux Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

import argparse
import contextlib
import multiprocessing
import os
import platform
import shlex
import signal
import shutil
import subprocess
import sys
import time
import re

OSX_DISTRIBUTION_NAME = "osx"
WIN32_DISTRIBUTION_NAME = "win32"

# vs vars
win_sdk_default = '10.0.18362.0'

APT_BASED_DISTROS = [
    'debian',
    'linuxmint',
    'raspbian',
    'trisquel',
    'ubuntu',
]

DNF_BASED_DISTROS = [
    'fedora', 'rhel', 'almalinux',
]

PACMAN_BASED_DISTROS = [
    'arch', 'parabola',
]

ZYPPER_BASED_DISTROS = [
    'opensuse-leap',
]

FLATPAK_BASED_RUNTIMES = [
    'org.gnome.Platform',
]

APT_INSTALL_SCRIPT = [
    'apt-get update',
    'apt-get install %(packages)s'
]

BREW_UNLINK_SCRIPT = [
    'brew unlink %(packages)s'
]

BREW_INSTALL_SCRIPT = [
    'brew update',
    'brew install %(packages)s',
    'brew link --force --overwrite %(packages)s'
]

RPM_INSTALL_SCRIPT = [
    'dnf update',
    'dnf install %(packages)s'
]

PACMAN_INSTALL_SCRIPT = [
    'pacman -Sy',
    'pacman -S --asdeps --needed %(packages)s'
]

ZYPPER_INSTALL_SCRIPT = [
    'zypper update',
    'zypper install %(packages)s'
]

ZYPPER_DEPENDENCIES = [
    # build system
    'autoconf', 'autoconf-archive', 'automake', 'cmake', 'make', 'patch', 'gcc-c++',
    'libtool', 'which', 'pandoc', 'nasm', 'doxygen', 'graphviz', 'systemd-devel',
    # contrib dependencies
    'curl', 'gzip', 'bzip2',
    # daemon
    'speexdsp-devel', 'speex-devel', 'libdbus-c++-devel', 'jsoncpp-devel', 'yaml-cpp-devel',
    'yasm', 'libuuid-devel', 'libnettle-devel', 'libopus-devel', 'libexpat-devel',
    'libgnutls-devel', 'msgpack-devel', 'libavcodec-devel', 'libavdevice-devel', 'pcre-devel',
    'alsa-devel', 'libpulse-devel', 'libudev-devel', 'libva-devel', 'libvdpau-devel',
    'libopenssl-devel', 'libavutil-devel',
]

ZYPPER_CLIENT_DEPENDENCIES = [
    # lrc
    'qt6-core-devel', 'qt6-dbus-devel', 'qt6-linguist-devel',
    # client-qt
    'qt6-svg-devel', 'qt6-multimedia-devel', 'qt6-declarative-devel',
    'qt6-quickcontrols2-devel',
    'qrencode-devel', 'NetworkManager-devel'
]

ZYPPER_QT_WEBENGINE = [
    'qt6-webenginecore-devel',
    'qt6-webenginequick-devel',
    'qt6-webenginewidgets-devel'
]

DNF_DEPENDENCIES = [
    'autoconf', 'autoconf-archive', 'automake', 'cmake', 'make', 'speexdsp-devel', 'pulseaudio-libs-devel',
    'libtool', 'dbus-devel', 'expat-devel', 'pcre-devel', 'doxygen', 'graphviz',
    'yaml-cpp-devel', 'boost-devel', 'dbus-c++-devel', 'dbus-devel',
    'libXext-devel', 'libXfixes-devel', 'yasm',
    'speex-devel', 'chrpath', 'check', 'astyle', 'uuid-c++-devel', 'gettext-devel',
    'gcc-c++', 'which', 'alsa-lib-devel', 'systemd-devel', 'libuuid-devel',
    'uuid-devel', 'gnutls-devel', 'nettle-devel', 'opus-devel', 'speexdsp-devel',
    'yaml-cpp-devel', 'swig', 'jsoncpp-devel',
    'patch', 'libva-devel', 'openssl-devel', 'libvdpau-devel', 'msgpack-devel',
    'sqlite-devel', 'openssl-static', 'pandoc', 'nasm',
    'bzip2'
]

DNF_CLIENT_DEPENDENCIES = [
    'libnotify-devel',
    'qt6-qtbase-devel',
    'qt6-qtsvg-devel', 'qt6-qtmultimedia-devel', 'qt6-qtdeclarative-devel',
    'qrencode-devel', 'NetworkManager-libnm-devel'
]

DNF_QT_WEBENGINE = ['qt6-qtwebengine-devel']

APT_DEPENDENCIES = [
    'autoconf', 'autoconf-archive', 'autopoint', 'automake', 'cmake', 'make', 'dbus', 'doxygen', 'graphviz',
    'g++', 'gettext', 'libasound2-dev', 'libavcodec-dev',
    'libavdevice-dev', 'libavformat-dev', 'libboost-dev',
    'libcppunit-dev', 'libdbus-1-dev',
    'libdbus-c++-dev', 'libebook1.2-dev', 'libexpat1-dev', 'libgnutls28-dev',
    'libgtk-3-dev', 'libjack-dev',
    'libopus-dev', 'libpcre3-dev', 'libpulse-dev', 'libssl-dev',
    'libspeex-dev', 'libspeexdsp-dev', 'libswscale-dev', 'libtool',
    'libudev-dev', 'libyaml-cpp-dev', 'sip-tester', 'swig',
    'uuid-dev', 'yasm', 'libjsoncpp-dev', 'libva-dev', 'libvdpau-dev', 'libmsgpack-dev',
    'pandoc', 'nasm', 'dpkg-dev', 'libsystemd-dev'
]

APT_CLIENT_DEPENDENCIES = [
    'qt6-base-dev', 'qt6-tools-dev', 'qt6-tools-dev-tools',
    'qt6-l10n-tools', 'libnotify-dev', 'libqt6sql6-sqlite',
    'libqt6core5compat6-dev', 'libqt6networkauth6-dev',
    'qt6-multimedia-dev', 'libqt6svg6-dev', 'qt6-declarative-dev',
    'qml6-module-qt-labs-qmlmodels',
    'qml6-module-qt5compat-graphicaleffects',
    'qml6-module-qtqml-workerscript',
    'qml6-module-qtmultimedia',
    'qml6-module-qtquick', 'qml6-module-qtquick-controls',
    'qml6-module-qtquick-dialogs', 'qml6-module-qtquick-layouts',
    'qml6-module-qtquick-shapes', 'qml6-module-qtquick-window',
    'qml6-module-qtquick-templates', 'qml6-module-qt-labs-platform',
    'libqrencode-dev', 'libnm-dev', 'hunspell'
]

APT_QT_WEBENGINE = [
    'libqt6webengine6-data', 'libqt6webenginecore6-bin',
    'qt6-webengine-dev', 'qt6-webengine-dev-tools',
    'qml6-module-qtwebengine', 'qml6-module-qtwebchannel']

PACMAN_DEPENDENCIES = [
    'autoconf', 'autoconf-archive', 'gettext', 'cmake', 'dbus', 'doxygen', 'graphviz',
    'gcc', 'ffmpeg', 'boost', 'cppunit', 'libdbus', 'dbus-c++', 'libe-book', 'expat',
    'jack', 'opus', 'pcre', 'libpulse', 'speex', 'speexdsp', 'libtool', 'yaml-cpp',
    'swig', 'yasm', 'make', 'patch', 'pkg-config',
    'automake', 'libva', 'libvdpau', 'openssl', 'pandoc', 'nasm', 'systemd-libs'
]

PACMAN_CLIENT_DEPENDENCIES = [
    # lrc
    'qt6-base',
    # client-qt
    'qt6-declarative', 'qt6-5compat', 'qt6-multimedia',
    'qt6-networkauth', 'qt6-shadertools',
    'qt6-svg', 'qt6-tools',
    'qrencode', 'libnm'
]

PACMAN_QT_WEBENGINE = ['qt6-webengine']

OSX_DEPENDENCIES = [
    'autoconf', 'cmake', 'gettext', 'pkg-config', 'qt6',
    'libtool', 'yasm', 'nasm', 'automake'
]

OSX_DEPENDENCIES_UNLINK = [
    'autoconf*', 'cmake*', 'gettext*', 'pkg-config*', 'qt*', 'qt@6.*',
    'libtool*', 'yasm*', 'nasm*', 'automake*', 'gnutls*', 'nettle*', 'msgpack*'
]

UNINSTALL_DAEMON_SCRIPT = [
    'make -C daemon uninstall'
]

ASSUME_YES_FLAG = ' -y'
ASSUME_YES_FLAG_PACMAN = ' --noconfirm'

GUIX_MANIFEST = 'extras/packaging/gnu-linux/guix/manifest.scm'


def run_powershell_cmd(cmd):
    p = subprocess.Popen(["powershell.exe", cmd], stdout=sys.stdout)
    p.communicate()
    p.wait()
    return


def run_dependencies(args):
    if args.distribution == WIN32_DISTRIBUTION_NAME:
        run_powershell_cmd(
            'Set-ExecutionPolicy Unrestricted; .\\extras\\scripts\\install-deps-windows.ps1')

    elif args.distribution in APT_BASED_DISTROS:
        if args.assume_yes:
            for i, _ in enumerate(APT_INSTALL_SCRIPT):
                APT_INSTALL_SCRIPT[i] += ASSUME_YES_FLAG
        execute_script(
            APT_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, APT_DEPENDENCIES))})
        if not args.no_webengine:
            APT_CLIENT_DEPENDENCIES.extend(APT_QT_WEBENGINE)
        execute_script(
            APT_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, APT_CLIENT_DEPENDENCIES))})

    elif args.distribution in DNF_BASED_DISTROS:
        if args.assume_yes:
            for i, _ in enumerate(DNF_INSTALL_SCRIPT):
                DNF_INSTALL_SCRIPT[i] += ASSUME_YES_FLAG
        execute_script(
            RPM_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, DNF_DEPENDENCIES))})
        if not args.no_webengine:
            DNF_CLIENT_DEPENDENCIES.extend(DNF_QT_WEBENGINE)
        execute_script(
            RPM_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, DNF_CLIENT_DEPENDENCIES))})

    elif args.distribution in PACMAN_BASED_DISTROS:
        if args.assume_yes:
            for i, _ in enumerate(PACMAN_INSTALL_SCRIPT):
                PACMAN_INSTALL_SCRIPT[i] += ASSUME_YES_FLAG_PACMAN
        execute_script(
            PACMAN_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, PACMAN_DEPENDENCIES))})
        if not args.no_webengine:
            PACMAN_CLIENT_DEPENDENCIES.extend(PACMAN_QT_WEBENGINE)
        execute_script(
            PACMAN_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, PACMAN_CLIENT_DEPENDENCIES))})

    elif args.distribution in ZYPPER_BASED_DISTROS:
        if args.assume_yes:
            for i, _ in enumerate(ZYPPER_INSTALL_SCRIPT):
                ZYPPER_INSTALL_SCRIPT[i] += ASSUME_YES_FLAG
        execute_script(
            ZYPPER_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, ZYPPER_DEPENDENCIES))})
        if not args.no_webengine:
            ZYPPER_CLIENT_DEPENDENCIES.extend(ZYPPER_QT_WEBENGINE)
        execute_script(
            ZYPPER_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, ZYPPER_CLIENT_DEPENDENCIES))})

    elif args.distribution == OSX_DISTRIBUTION_NAME:
        execute_script(
            BREW_UNLINK_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, OSX_DEPENDENCIES_UNLINK))},
            False
        )
        execute_script(
            BREW_INSTALL_SCRIPT,
            {"packages": ' '.join(map(shlex.quote, OSX_DEPENDENCIES))},
            False
        )

    elif args.distribution == WIN32_DISTRIBUTION_NAME:
        print("The win32 version does not install dependencies with this script.\nPlease continue with the --install instruction.")
        sys.exit(1)
    elif args.distribution == 'guix':
        print(f"Building the profile defined in '{GUIX_MANIFEST}'...")
        execute_script([f'guix shell --manifest={GUIX_MANIFEST} -- true'])

    else:
        print("Not yet implemented for current distribution (%s). Please continue with the --install instruction. Note: You may need to install some dependencies manually." %
              args.distribution)
        sys.exit(1)


def run_init(args):
    """Initialize the git submodules and install the commit-msg hook."""
    subprocess.run(["git", "submodule", "update", "--init"],
                   check=True)

    client_hooks_dir = '.git/hooks'
    daemon_hooks_dir = '.git/modules/daemon/hooks'

    print("Installing commit-msg hooks...")
    # Copy the commit-msg hook to all modules in the same way.
    for hooks_dir in [client_hooks_dir, daemon_hooks_dir]:
        if not os.path.exists(hooks_dir):
            os.makedirs(hooks_dir)
        copy_file("./extras/scripts/commit-msg",
                  os.path.join(hooks_dir, "commit-msg"))

    print("Installing pre-commit hooks...")
    format_script = "./extras/scripts/format.py"
    # Prepend with the python executable if on Windows (not WSL).
    if sys.platform == 'win32':
        format_script = f'python {format_script}'
    # The client submodule has QML files, so we need to run qmlformat on it,
    # and thus need to supply the Qt path.
    execute_script([f'{format_script} --install {client_hooks_dir}'
                    f' --qt {args.qt}'],
                   {"path": client_hooks_dir})

    # The daemon submodule has no QML files, so we don't need to run
    # qmlformat on it, and thus don't need to supply the Qt path.
    execute_script([f'{format_script} --install {daemon_hooks_dir}'],
                   {"path": daemon_hooks_dir})


def copy_file(src, dest):
    print(f'Copying: {src} to {dest}')
    try:
        shutil.copy2(src, dest)
    # e.g. src and dest are the same file
    except shutil.Error as e:
        print(f'Error: {e}')
    # e.g. source or destination doesn't exist
    except IOError as e:
        print(f'Error: {e.strerror}')


@contextlib.contextmanager
def cwd(path):
    owd = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(owd)


def run_install(args):
    # Platforms with special compilation scripts
    if args.distribution == WIN32_DISTRIBUTION_NAME:
        if not args.pywinmake:
            with cwd('daemon/compat/msvc'):
                execute_script([f'python winmake.py -iv -s {args.sdk} -b daemon'])

        build_windows = 'extras/scripts/build-windows.py'
        execute_script([f'python {build_windows} --init'])
        execute_script([f'python {build_windows} --qt={args.qt}'])
        return True

    # Unix-like platforms
    environ = os.environ.copy()

    install_args = ['-p', str(multiprocessing.cpu_count())]
    if args.static:
        install_args.append('-s')
    if args.global_install:
        install_args.append('-g')
    if args.prefix:
        install_args += ('-P', args.prefix)
    if not args.priv_install:
        install_args.append('-u')
    if args.debug:
        install_args.append('-d')
    if args.asan:
        install_args.append('-A')
    if args.no_libwrap:
        install_args.append('-W')
    if args.no_webengine:
        install_args.append('-w')
    if args.arch:
        install_args += ('-a', args.arch)

    if args.distribution == OSX_DISTRIBUTION_NAME:
        # The `universal_newlines` parameter has been renamed to `text` in
        # Python 3.7+ and triggering automatical binary to text conversion is
        # what it actually does
        proc = subprocess.run(["brew", "--prefix", "qt6"],
                              stdout=subprocess.PIPE, check=True,
                              universal_newlines=True)

        environ['CMAKE_PREFIX_PATH'] = proc.stdout.rstrip("\n")
        environ['CONFIGURE_FLAGS'] = '--without-dbus'
        if not args.qt:
            raise Exception(
                'provide the Qt path using --qt=/qt/install/prefix')
        install_args += ("-Q", args.qt)
    else:
        if args.distribution in ZYPPER_BASED_DISTROS:
            # fix jsoncpp pkg-config bug, remove when jsoncpp package bumped
            environ['JSONCPP_LIBS'] = "-ljsoncpp"
        if args.qt:
            install_args += ("-Q", args.qt)

    command = ['extras/scripts/install.sh'] + install_args

    if 'TARBALLS' not in os.environ:
        print('info: consider setting the TARBALLS environment variable '
              'to a stable writable location to avoid loosing '
              'cached tarballs')

    if args.distribution == 'guix':
        if args.global_install:
            print('error: global install is not supported when using Guix.')
            sys.exit(1)
        # Run the build in an isolated container.
        share_tarballs_args = []
        if 'TARBALLS' in os.environ:
            share_tarballs_args = ['--preserve=TARBALLS',
                                   f'--share={os.environ["TARBALLS"]}']
        command = ['guix', 'shell', f'--manifest={GUIX_MANIFEST}',
                   '--symlink=/usr/bin/env=bin/env',
                   '--symlink=/etc/ssl/certs=etc/ssl/certs',
                   '--container', '--network'] + share_tarballs_args \
            + ['--'] + command

    print(f'info: Building/installing using the command: {" ".join(command)}')
    return subprocess.run(command, env=environ, check=True)


def run_uninstall(args):
    execute_script(UNINSTALL_DAEMON_SCRIPT)

    BUILD_DIR = 'build-global' if args.global_install else 'build'

    if (os.path.exists(BUILD_DIR)):
        UNINSTALL_CLIENT_SCRIPT = [
            f'make -C {BUILD_DIR} uninstall',
            f'rm -rf {BUILD_DIR}'
        ]
        execute_script(UNINSTALL_CLIENT_SCRIPT)


def run_clean():
    execute_script(['git clean -xfd',
                    'git submodule foreach git clean -xfd'])


def clean_contribs(contribs):
    """
    Helper to clean one or more of the libjami contribs.

    Takes a list of contrib names(space separated) to clean, or 'all' to clean all contribs.

    Contribs are assumed to be in the contrib_dir: daemon/contrib
    Artifacts to remove include:
    - build directory: <contrib_dir>/<native_dir>/<contrib_name>
    - build stamp: <contrib_dir>/<native_dir>/.<contrib_name>
    - tarball: <contrib_dir>/tarballs/<contrib_name>*.tar.*
    - build artifacts (we don't care about the contents of share):
        - <contrib_dir>/<abi_triplet>/bin/<contrib_name>
        - <contrib_dir>/<abi_triplet>/lib/<contrib_name>*
        - <contrib_dir>/<abi_triplet>/include/<contrib_name>*
    """

    # Not supported on Windows
    if platform.system() == 'Windows':
        print('Cleaning contribs is not supported on Windows. Exiting.')
        sys.exit(1)

    # Assume we are using the submodule here.
    contrib_dir = 'daemon/contrib'
    sub_dirs = os.listdir(contrib_dir)

    # Let's find the abi triplet:
    # The abi_triplet is 3 parts: <arch>-<vendor>-<sys> and should be the only directory
    # named like that in the contrib directory. We can use a regex to find it.
    triplet_pattern = re.compile(r'^[a-zA-Z0-9_]+-[a-zA-Z0-9_]+-[a-zA-Z0-9_]+$')
    def is_triplet(s):
        return bool(triplet_pattern.match(s))
    abi_triplet = ''
    for sub_dir in sub_dirs:
        if is_triplet(sub_dir):
            abi_triplet = sub_dir
            break

    # If we didn't find the abi triplet, we need to stop.
    if abi_triplet == '':
        print('Could not find the abi triplet for the contribs. Exiting.')
        sys.exit(1)

    # Let's find the native build source directory (native-*)
    native_dir = ''
    for sub_dir in sub_dirs:
        if sub_dir.startswith('native'):
            native_dir = os.path.join(contrib_dir, sub_dir)
            break

    # If we didn't find the native build source directory, we need to stop.
    if native_dir == '':
        print('Could not find the native build source directory. Exiting.')
        sys.exit(1)

    # If contribs is 'all', construct the list of all contribs from the contrib native directory
    # list of directories only
    if contribs == ['all']:
        contribs = [d for d in os.listdir(native_dir) if os.path.isdir(os.path.join(native_dir, d))]

    # Clean each contrib
    for contrib in contribs:
        print(f'Cleaning contrib: {contrib} for {abi_triplet} in {native_dir}')
        build_dir = os.path.join(native_dir, contrib, '*')
        build_stamp = os.path.join(native_dir, f'.{contrib}*')
        tarball = os.path.join(contrib_dir, 'tarballs', f'{contrib}*.tar.*')
        bins = os.path.join(contrib_dir, abi_triplet, 'bin', contrib)
        libs = os.path.join(contrib_dir, abi_triplet, 'lib', f'lib{contrib}*')
        includes = os.path.join(contrib_dir, abi_triplet, 'include', f'{contrib}*')

        # EXCEPTIONS: pjproject and ffmpeg
        if contrib == 'pjproject':
            libs =  f' {os.path.join(contrib_dir, abi_triplet, "lib", "libpj*")}' \
                    f' {os.path.join(contrib_dir, abi_triplet, "lib", "libsrtp*")}'
            includes = os.path.join(contrib_dir, abi_triplet, 'include', 'pj*')
        elif contrib == 'ffmpeg':
            libs = f' {os.path.join(contrib_dir, abi_triplet, "lib", "libav*")}' \
                   f' {os.path.join(contrib_dir, abi_triplet, "lib", "libsw*")}'
            includes = f' {os.path.join(contrib_dir, abi_triplet, "include", "libav*")}' \
                       f' {os.path.join(contrib_dir, abi_triplet, "include", "libsw*")}'

        # For a dry run:
        #  execute_script([f'find {build_dir} {build_stamp} {tarball} {bins} {libs} {includes}'], fail=False)

        execute_script([f'rm -rf {build_dir} {build_stamp} {tarball} {bins} {libs} {includes}'], fail=False)


def run_run(args):
    run_env = os.environ

    if args.debug:
        # Ignore the interruption signal when using GDB, as it's
        # common to use C-c when debugging and we do not want the
        # Python script to abort the debugging session.
        signal.signal(signal.SIGINT, signal.SIG_IGN)

    try:
        if args.no_libwrap:
            jamid_log = open("daemon.log", 'a')
            jamid_log.write('=== Starting daemon (%s) ===' %
                            time.strftime("%d/%m/%Y %H:%M:%S"))
            jamid_process = subprocess.Popen(
                ["./install/libexec/jamid", "-c", "-d"],
                stdout=jamid_log,
                stderr=jamid_log)

            with open('daemon.pid', 'w') as f:
                f.write(str(jamid_process.pid)+'\n')

        client_log = open('jami.log', 'a')
        client_log.write('=== Starting client (%s) ===' %
                         time.strftime("%d/%m/%Y %H:%M:%S"))
        jami_cmdline = ['install/bin/jami', '-d']
        if args.debug:
            jami_cmdline = ['gdb', '-ex', 'run', '--args'] + jami_cmdline

        print('Invoking jami with: {}'.format(str.join(' ', jami_cmdline)))
        if args.debug:
            print('Debugging with GDB; NOT redirecting output to log file')
        client_process = subprocess.Popen(
            jami_cmdline,
            stdout=False if args.debug else client_log,
            stderr=False if args.debug else client_log,
            env=run_env)

        with open('jami.pid', 'w') as f:
            f.write(str(client_process.pid)+'\n')

        if args.debug and args.no_libwrap:
            subprocess.call(['gdb', './install/libexec/jamid'])

        if not args.background:
            if args.no_libwrap:
                jamid_process.wait()
            client_process.wait()

    except KeyboardInterrupt:
        print("\nCaught KeyboardInterrupt...")

    finally:
        if args.debug:
            # Restore the default signal handler for SIGINT.
            signal.signal(signal.SIGINT, signal.SIG_DFL)
        if not args.background:
            try:
                # Only kill the processes if they are running, as they
                # could have been closed by the user.
                print("Killing processes...")
                if args.no_libwrap:
                    jamid_log.close()
                    if jamid_process.poll() is None:
                        jamid_process.kill()
                client_log.close()
                if client_process.poll() is None:
                    client_process.kill()
            except UnboundLocalError:
                # Its okay! We crashed before we could start a process
                # or open a file.  All that matters is that we close
                # files and kill processes in the right order.
                pass
    return True


def run_stop(args):
    STOP_SCRIPT = ['xargs kill < jami.pid',
                   'xargs kill < daemon.pid']
    execute_script(STOP_SCRIPT)


def execute_script(script, settings=None, fail=True):
    if settings is None:
        settings = {}
    for line in script:
        line = line % settings
        rv = os.system(line)
        if rv and fail:
            print('Error executing script! Exit code: %s (%s)' %
                  (rv, script), file=sys.stderr)
            sys.exit(1)


def has_guix():
    """Check whether the 'guix' command is available."""
    with open(os.devnull, 'w') as f:
        try:
            subprocess.run(["sh", "-c", "command -v guix"],
                           check=True, stdout=f)
        except subprocess.CalledProcessError:
            return False
        else:
            return True


def validate_args(parsed_args):
    """Validate the args values, exit if error is found"""

    # Filter unsupported distributions.
    supported_distros = \
        [OSX_DISTRIBUTION_NAME, WIN32_DISTRIBUTION_NAME, 'guix'] + \
        APT_BASED_DISTROS + DNF_BASED_DISTROS + PACMAN_BASED_DISTROS \
        + ZYPPER_BASED_DISTROS + FLATPAK_BASED_RUNTIMES

    if (parsed_args.distribution == 'no-check'
            or 'JAMI_BUILD_NO_CHECK' in os.environ):
        return

    if parsed_args.distribution not in supported_distros:
        print(f'WARNING: Distribution \'{parsed_args.distribution}\' is not '
              f'supported. Choose one of: {", ".join(supported_distros)}. '
              'Alternatively, you may force execution of this script '
              'by providing the \'--distribution=no-check\' argument or by '
              'exporting the JAMI_BUILD_NO_CHECK environment variable.',
              file=sys.stderr)
        sys.exit(1)

    # On Windows, version 10 or later is needed to build Jami.
    if parsed_args.distribution == WIN32_DISTRIBUTION_NAME:
        if hasattr(sys, 'getwindowsversion') and sys.getwindowsversion()[0] < 10:
            print('Windows 10 or later is needed to build Jami')
            sys.exit(1)


def parse_args():
    ap = argparse.ArgumentParser(description="Jami build tool")

    ga = ap.add_mutually_exclusive_group(required=True)
    ga.add_argument(
        '--init', action='store_true',
        help='Init Jami repository')
    ga.add_argument(
        '--dependencies', action='store_true',
        help='Install Jami build dependencies')
    ga.add_argument(
        '--install', action='store_true',
        help='Build and install Jami')
    ga.add_argument(
        '--clean', action='store_true',
        help='Call "git clean" on every repository of the project'
    )
    ga.add_argument(
        '--uninstall', action='store_true',
        help='Uninstall Jami')
    ga.add_argument(
        '--run', action='store_true',
        help='Run the Jami daemon and client')
    ga.add_argument(
        '--stop', action='store_true',
        help='Stop the Jami processes')

    ap.add_argument('--distribution')
    ap.add_argument('--prefix')
    ap.add_argument('--static', default=False, action='store_true')
    ap.add_argument('--global-install', default=False, action='store_true')
    ap.add_argument('--debug', default=False, action='store_true',
                    help='Build with debug support; run in GDB')
    ap.add_argument('--asan', default=False, action='store_true',
                    help='Build both daemon and client with ASAN')
    ap.add_argument('--background', default=False, action='store_true')
    ap.add_argument('--no-priv-install', dest='priv_install',
                    default=True, action='store_false')
    ap.add_argument('--qt', type=str,
                    help='Use the Qt path supplied')
    ap.add_argument('--no-libwrap', dest='no_libwrap',
                    default=False, action='store_true',
                    help='Disable libwrap. Also set --disable-shared option to daemon configure')
    ap.add_argument('-y', '--assume-yes', default=False, action='store_true',
                    help='Assume yes (do not prompt user) for dependency installations through the system package manager')
    ap.add_argument('--no-webengine', dest='no_webengine',
                    default=False, action='store_true',
                    help='Do not use Qt WebEngine.')
    ap.add_argument('--arch')
    ap.add_argument('--clean-contribs', nargs='+',
                    help='Clean the specified contribs (space separated) or \
                          "all" to clean all contribs before building.')
    ap.add_argument('--pywinmake', dest='pywinmake',
                    default=False, action='store_true',
                    help='Build Jami for Windows using pywinmake')

    dist = choose_distribution()

    if dist == WIN32_DISTRIBUTION_NAME:
        ap.add_argument('--sdk', default=win_sdk_default, type=str,
                        help='Windows use only, specify Windows SDK version')

    parsed_args = ap.parse_args()

    if parsed_args.distribution:
        parsed_args.distribution = parsed_args.distribution.lower()
    else:
        parsed_args.distribution = dist

    validate_args(parsed_args)

    return parsed_args


def choose_distribution():
    system = platform.system().lower()

    if system == "linux" or system == "linux2":
        if os.path.isfile("/etc/arch-release"):
            return "arch"
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    k, v = line.split("=")
                    if k.strip() == 'ID':
                        return v.strip().replace('"', '').split(' ')[0]
        except FileNotFoundError:
            if has_guix():
                return 'guix'
            return 'Unknown'
    elif system == "darwin":
        return OSX_DISTRIBUTION_NAME
    elif system == "windows":
        return WIN32_DISTRIBUTION_NAME

    return 'Unknown'


def main():
    parsed_args = parse_args()

    # Clean contribs if specified first.
    if parsed_args.clean_contribs:
        clean_contribs(parsed_args.clean_contribs)

    if parsed_args.dependencies:
        run_dependencies(parsed_args)

    elif parsed_args.init:
        run_init(parsed_args)

    elif parsed_args.clean:
        run_clean()

    elif parsed_args.install:
        run_install(parsed_args)

    elif parsed_args.uninstall:
        run_uninstall(parsed_args)

    elif parsed_args.run:
        if (parsed_args.distribution == 'guix'
                and 'GUIX_ENVIRONMENT' not in os.environ):
            # Relaunch this script, this time in a pure Guix environment.
            guix_args = ['shell', '--pure',
                         # to allow pulseaudio to connect to an existing server
                         "-E", "XAUTHORITY", "-E", "XDG_RUNTIME_DIR",
                         f'--manifest={GUIX_MANIFEST}', '--']
            args = sys.argv + ['--distribution=guix']
            print('Running in a guix shell spawned with: guix {}'
                  .format(str.join(' ', guix_args + args)))
            os.execlp('guix', 'guix', *(guix_args + args))
        else:
            run_run(parsed_args)

    elif parsed_args.stop:
        run_stop(parsed_args)


if __name__ == "__main__":
    main()
