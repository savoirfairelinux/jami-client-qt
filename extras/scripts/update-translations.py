#!/usr/bin/python

##
##  Copyright (C) 2016-2025 Savoir-faire Linux Inc.
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
##

import os
import subprocess
import glob
import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(description='Update translation files for the Jami client.')
    parser.add_argument('--minimum-perc', type=int, default=1,
                      help='Minimum translation percentage to pull (default: 1)')

    # Add mutually exclusive group for operations
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--lupdate-only', action='store_true',
                      help='Only run lupdate to update translation files')
    group.add_argument('--push-only', action='store_true',
                      help='Only push sources to Transifex')
    group.add_argument('--pull-only', action='store_true',
                      help='Only pull translations from Transifex')

    return parser.parse_args()

def run_lupdate(client_dir):
    print(f"== Updating translations for {client_dir}")

    # Check if lupdate is available and working
    try:
        result = subprocess.run("lupdate -version", shell=True, capture_output=True, check=False)
        if result.returncode != 0:
            print("WARNING: lupdate check failed. Please verify that the correct version of lupdate is in your PATH")
            print("You may need to install Qt development tools or adjust your PATH")
            return
    except Exception as e:
        print(f"WARNING: Could not run lupdate: {e}")
        print("Please verify that the correct version of lupdate is in your PATH")
        return

    ts_file_names = glob.glob(os.path.join(client_dir, "translations", "**", "*.ts"), recursive=True)
    if not ts_file_names:
        raise RuntimeError("No translation files found")

    if os.name == 'nt':  # Windows
        for ts_file in ts_file_names:
            lupdate_command = f"lupdate -extensions cpp,h,qml {client_dir}/src -ts {ts_file} -no-obsolete"
            try:
                process = subprocess.Popen("cmd", stdin=subprocess.PIPE, shell=True)
                process.communicate(lupdate_command.encode())
                print(f"Updated {ts_file}")
            except subprocess.CalledProcessError:
                print(f"Lupdate failure for {ts_file}")
    else:  # Linux
        for ts_file in ts_file_names:
            lupdate_command = f"lupdate -extensions cpp,h,qml {client_dir}/src -ts {ts_file} -no-obsolete"
            try:
                subprocess.run(lupdate_command, shell=True, check=True)
                print(f"Updated {ts_file}")
            except subprocess.CalledProcessError:
                print(f"Lupdate failure for {ts_file}")

def push_sources():
    print("== Pushing sources")
    os.system("tx push -s")

def pull_translations(minimum_perc):
    print("== Pulling translations")
    os.system(f"tx pull -af --minimum-perc={minimum_perc}")

def main():
    args = parse_arguments()
    os.chdir('../..')
    client_dir = os.getcwd()

    # Run only the specified operation, or all if none specified
    if args.lupdate_only:
        run_lupdate(client_dir)
    elif args.push_only:
        push_sources()
    elif args.pull_only:
        pull_translations(args.minimum_perc)
    else:
        # Run all operations in sequence
        run_lupdate(client_dir)
        push_sources()
        pull_translations(args.minimum_perc)

    print("== All done you can commit now")

if __name__ == "__main__":
    main()