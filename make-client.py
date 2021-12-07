#!/usr/bin/env python3

import tempfile
import re
import sys
import os
import subprocess
import platform
import argparse
import multiprocessing
import fileinput
from enum import Enum

qt_version_default = '6.2.0'

vs_where_path = os.path.join(
    os.environ['ProgramFiles(x86)'], 'Microsoft Visual Studio', 'Installer', 'vswhere.exe'
)

host_is_64bit = (False, True)[platform.machine().endswith('64')]
this_dir = os.path.dirname(os.path.realpath(__file__))
build_dir = os.path.join(this_dir, 'build')

temp_path = os.environ['TEMP']
openssl_include_dir = 'C:\\Qt\\Tools\\OpenSSL\\Win_x64\\include\\openssl'

qt_path = os.path.join('c:', os.sep, 'Qt')
qt_kit_path = 'msvc2019_64'
qt_root_path = os.getenv('QT_ROOT_DIRECTORY', qt_path)

# project path
unit_test_project = os.path.join(build_dir, 'tests', 'unittests.vcxproj')
qml_test_project = os.path.join(build_dir, 'tests', 'qml_tests.vcxproj')

# test executable command
qml_test_exe = os.path.join(this_dir, 'x64', 'test', 'qml_tests.exe -input ') + \
               os.path.join(this_dir, 'tests', 'qml')
unit_test_exe = os.path.join(this_dir, 'x64', 'test', 'unittests.exe')

def execute_cmd(cmd, with_shell=False, env_vars={}):
    if(bool(env_vars)):
        p = subprocess.Popen(cmd, shell=with_shell,
                             stdout=sys.stdout,
                             env=env_vars)
    else:
        p = subprocess.Popen(cmd, shell=with_shell)
    _, _ = p.communicate()
    return p.returncode


def getLatestVSVersion():
    args = [
        '-latest',
        '-products *',
        '-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
        '-property installationVersion'
    ]
    cmd = [vs_where_path] + args
    output = subprocess.check_output(' '.join(cmd)).decode('utf-8')
    if output:
        return output.splitlines()[0].split('.')[0]
    else:
        return

def findVSLatestDir():
    args = [
        '-latest',
        '-products *',
        '-requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
        '-property installationPath'
    ]
    cmd = [vs_where_path] + args
    output = subprocess.check_output(
        ' '.join(cmd)).decode('utf-8', errors='ignore')
    if output:
        return output.splitlines()[0]
    else:
        return

def getQtVersionNumber(qt_version, version_type):
    version_list = qt_version.split('.')
    return version_list[version_type.value]

def findMSBuild():
    filename = 'MSBuild.exe'
    for root, _, files in os.walk(findVSLatestDir() + r'\\MSBuild'):
        if filename in files:
            return os.path.join(root, filename)

def getMSBuildArgs(arch, config_str, toolset, configuration_type=''):
    msbuild_args = [
        '/nologo',
        '/verbosity:minimal',
        '/maxcpucount:' + str(multiprocessing.cpu_count()),
        '/p:Platform=' + arch,
        '/p:Configuration=' + config_str,
        '/p:useenv=true']
    if (toolset != ''):
        msbuild_args.append('/p:PlatformToolset=' + toolset)
    if (configuration_type != ''):
        msbuild_args.append('/p:ConfigurationType=' + configuration_type)
    return msbuild_args

def getVSEnv(arch='x64', platform='', version=''):
    env_cmd = 'set path=%path:"=% && ' + \
        getVSEnvCmd(arch, platform, version) + ' && set'
    p = subprocess.Popen(env_cmd,
                         shell=True,
                         stdout=subprocess.PIPE)
    stdout, _ = p.communicate()
    out = stdout.decode('utf-8', errors='ignore').split("\r\n")[5:-1]
    return dict(s.split('=', 1) for s in out)


def getVSEnvCmd(arch='x64', platform='', version=''):
    vcEnvInit = [findVSLatestDir() + r'\VC\Auxiliary\Build\"vcvarsall.bat']
    if platform != '':
        args = [arch, platform, version]
    else:
        args = [arch, version]
    if args:
        vcEnvInit.extend(args)
    vcEnvInit = 'call \"' + ' '.join(vcEnvInit)
    return vcEnvInit


def replace_necessary_vs_prop(project_path, toolset, sdk_version):
    # force toolset
    replace_vs_prop(project_path,
                    'PlatformToolset',
                    toolset)
    # force unicode
    replace_vs_prop(project_path,
                    'CharacterSet',
                    'Unicode')
    # force sdk_version
    replace_vs_prop(project_path,
                    'WindowsTargetPlatformVersion',
                    sdk_version)

def build_project(msbuild, msbuild_args, proj, env_vars):
    args = []
    args.extend(msbuild_args)
    args.append(proj)
    cmd = [msbuild]
    cmd.extend(args)
    if (execute_cmd(cmd, True, env_vars)):
        print("Build failed when building ", proj)
        sys.exit(1)


def replace_vs_prop(filename, prop, val):
    p = re.compile(r'(?s)<' + prop + r'\s?.*?>(.*?)<\/' + prop + r'>')
    val = r'<' + prop + r'>' + val + r'</' + prop + r'>'
    with fileinput.FileInput(filename, inplace=True) as file:
        for line in file:
            print(re.sub(p, val, line), end='')


def deps(arch, toolset, qtver):
    print('Deps Qt Client Release|' + arch)

    # Fetch QRencode
    print('Generate QRencode')
    apply_cmd = "git apply --reject --ignore-whitespace --whitespace=fix"
    qrencode_path = 'qrencode-win32'
    if (os.path.isdir(qrencode_path)):
        os.system('rmdir qrencode-win32 /s /q')
    if (execute_cmd("git clone https://github.com/BlueDragon747/qrencode-win32.git", True)):
        print("Git clone failed when cloning from https://github.com/BlueDragon747/qrencode-win32.git")
        sys.exit(1)
    if(execute_cmd("cd qrencode-win32 && git checkout d6495a2aa74d058d54ae0f1b9e9e545698de66ce && "
                    + apply_cmd + os.path.join(' ..', 'qrencode-win32.patch'), True)):
        print("qrencode-win32 set up error")
        sys.exit(1)

    print('Building qrcodelib')

    vs_env_vars = {}
    vs_env_vars.update(getVSEnv())

    msbuild = findMSBuild()
    if not os.path.isfile(msbuild):
        raise IOError('msbuild.exe not found. path=' + msbuild)
    msbuild_args = getMSBuildArgs(arch, 'Release-Lib', toolset)

    this_dir = os.path.dirname(os.path.realpath(__file__))
    proj_path = os.path.join(this_dir, 'qrencode-win32' ,'qrencode-win32',
                             'vc8', 'qrcodelib', 'qrcodelib.vcxproj')

    build_project(msbuild, msbuild_args, proj_path, vs_env_vars)


def build(arch, config_str, qtver, tests=False):
    print("Building with Qt " + qtver)

    vs_env_vars = {}
    vs_env_vars.update(getVSEnv())

    qt_dir = os.path.join(qt_root_path, qtver, qt_kit_path)

    cmake_options = [
        '-DCMAKE_PREFIX_PATH=' + qt_dir,
        '-DCMAKE_BUILD_TYPE=' + config_str
    ]
    if tests:
        cmake_options.append('-DENABLE_TESTS=true')

    if not os.path.exists(build_dir):
        os.makedirs(build_dir)
    os.chdir(build_dir)

    cmd = ['cmake', '..']
    if (config_str == 'Release'):
        print('Generating project using cmake ' + config_str + '|' + arch)
    elif (config_str == 'Beta'):
        print('Generating project using cmake ' + config_str + '|' + arch)
        cmake_options.append('-DBETA=1')
        config_str = 'Release'
    elif (config_str == 'ReleaseCompile'):
        print('Generating project using qmake ' + config_str + '|' + arch)
        cmake_options.append('-DReleaseCompile=1')
        config_str = 'Release'

    cmd.extend(cmake_options)
    if(execute_cmd(cmd, False, vs_env_vars)):
        print("Cmake file generate error")
        sys.exit(1)

    print('Building projects in ' + config_str + '|' + arch)

    print('Building projects in ' + config_str + '|' + arch)
    cmd = ['cmake', '--build', '.', '--config', config_str]
    if(execute_cmd(cmd, False, vs_env_vars)):
        print("Cmake build error")
        sys.exit(1)

def build_tests_projects(arch, config_str, msbuild, vs_env_vars, toolset,
                         sdk_version, force_option=True):
    print('Building test projects')

    test_projects_application_list = [unit_test_project, qml_test_project]

    # unit tests, qml tests
    for project in test_projects_application_list:
        if (force_option):
            replace_necessary_vs_prop(project, toolset, sdk_version)

        msbuild_args = getMSBuildArgs(arch, config_str, toolset)
        build_project(msbuild, msbuild_args, project, vs_env_vars)

def run_tests(mute_jamid, output_to_files):
    print('Running client tests')

    test_exe_command_list = [qml_test_exe, unit_test_exe]

    if mute_jamid:
        test_exe_command_list[0] += ' -mutejamid'
        test_exe_command_list[1] += ' -mutejamid'
    if output_to_files:
        test_exe_command_list[0] += ' -o ' + os.path.join(this_dir, 'x64', 'test', 'qml_tests.txt')
        test_exe_command_list[1] += ' > ' + os.path.join(this_dir, 'x64', 'test', 'unittests.txt')

    test_result_code = 0

    # make sure that the tests are rendered offscreen
    os.environ["QT_QPA_PLATFORM"] = 'offscreen'
    os.environ["QT_QUICK_BACKEND"] = 'software'

    for test_exe_command in test_exe_command_list:
        if (execute_cmd(test_exe_command, True)):
            test_result_code = 1
    sys.exit(test_result_code)

def parse_args():
    ap = argparse.ArgumentParser(description="Client qt build tool")
    subparser = ap.add_subparsers(dest="subparser_name")

    ap.add_argument(
        '-b', '--build', action='store_true',
        help='Build Qt Client')
    ap.add_argument(
        '-a', '--arch', default='x64',
        help='Sets the build architecture')
    ap.add_argument(
        '-t', '--runtests', action='store_true',
        help='Build and run tests')
    ap.add_argument(
        '-d', '--deps', action='store_true',
        help='Build Deps for Qt Client')
    ap.add_argument(
        '-bt', '--beta', action='store_true',
        help='Build Qt Client in Beta Config')
    ap.add_argument(
        '-q', '--qtver', default=qt_version_default,
        help='Sets the version of Qmake')

    run_test = subparser.add_parser('runtests')
    run_test.add_argument(
        '-md', '--mutejamid', action='store_true', default=False,
        help='Avoid jamid logs')
    run_test.add_argument(
        '-o', '--outputtofiles', action='store_true', default=False,
        help='Output tests log into files')

    parsed_args = ap.parse_args()

    return parsed_args


def main():
    if not host_is_64bit:
        print('These scripts will only run on a 64-bit Windows system for now!')
        sys.exit(1)

    if int(getLatestVSVersion()) < 15:
        print('These scripts require at least Visual Studio v15 2017!')
        sys.exit(1)

    parsed_args = parse_args()

    if parsed_args.subparser_name == 'runtests':
        run_tests(parsed_args.mutejamid, parsed_args.outputtofiles)

    if parsed_args.deps:
        deps(parsed_args.arch, parsed_args.qtver)

    if parsed_args.build:
        build(parsed_args.arch, 'Release',
              parsed_args.qtver, parsed_args.runtests)

    if parsed_args.beta:
        build(parsed_args.arch, 'Beta', 
              parsed_args.qtver, parsed_args.runtests)


if __name__ == '__main__':
    main()
