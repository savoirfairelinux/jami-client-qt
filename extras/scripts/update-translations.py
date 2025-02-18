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
import shutil
import subprocess
import glob

def get_qt_dir(qtver):
    if os.name == 'nt':  # Windows
        qt_dir = f"C:/Qt/{qtver}/msvc2019_64"
        if not os.path.exists(qt_dir):
            qt_dir = f"C:/Qt/{qtver}/msvc2017_64"
    else:  # Linux or other Unix-like systems
        qt_dir = f"/usr/lib/qt6"
        if not os.path.exists(qt_dir):
            qt_dir = f"/usr/local/Qt-{qtver}"
    return qt_dir

def main(qtver="6.6"):
    script_dir = os.getcwd()
    os.chdir('../..')
    client_dir = os.getcwd()
    print(f"== script used at {script_dir}")
    print(f"== Updating translations for {client_dir}")
    qt_dir = get_qt_dir(qtver)
    print(f"== Using Qt from {qt_dir}")
    lupdate = os.path.join(qt_dir, "bin", "lupdate")
    print(f"== Using lupdate from {lupdate}")

    if not os.path.exists(lupdate):
        raise RuntimeError(f"lupdate tool not found at {lupdate}")

    #We need to go back two times in the file hierarchy before finding the translations folder
    ts_file_names = glob.glob(os.path.join(client_dir, "translations", "**", "*.ts"), recursive=True)
    if not ts_file_names:
        raise RuntimeError("No translation files found")

    ts_file_names_str = " ".join(ts_file_names)

    lupdate_command = f"{lupdate} -extensions cpp,h,qml {client_dir}/src -ts {ts_file_names_str} -no-obsolete"
    print("== Updating from sources")
    try:
        subprocess.run(lupdate_command, shell=True, check=True)
    except subprocess.CalledProcessError:
        print("Attempting with 'lupdate-qt5'")
        lupdate = lupdate.replace("lupdate.exe", "lupdate-qt5.exe")
        lupdate_command = f"{lupdate} -extensions cpp,h,qml {client_dir}/src -ts {ts_file_names_str} -no-obsolete"
        subprocess.run(lupdate_command, shell=True, check=True)


    print("== All done you can commit now")

if __name__ == "__main__":
    main()