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

def get_qt_dir(qtver="6.6.2"):
    qt_dir = f"/usr/lib/qt6"
    if not os.path.exists(qt_dir):
        qt_dir = f"/usr/local/Qt-{qtver}"
    return qt_dir

def main():
    os.chdir('../..')
    client_dir = os.getcwd()
    print(f"== Updating translations for {client_dir}")

    ts_file_names = glob.glob(os.path.join(client_dir, "translations", "**", "*.ts"), recursive=True)
    if not ts_file_names:
        raise RuntimeError("No translation files found")

    ts_file_names_str = " ".join(ts_file_names)
    if os.name == 'nt':  # Windows
        lupdate_command = f"lupdate -extensions cpp,h,qml {client_dir}/src -ts {ts_file_names_str} -no-obsolete"
        try:
            process=subprocess.Popen("cmd", stdin=subprocess.PIPE, shell=True)
            process.communicate(lupdate_command.encode())
        except subprocess.CalledProcessError:
            print("Lupdate failure")
    else : # Linux
        qt_dir = get_qt_dir()
        print(f"== Using Qt from {qt_dir}")
        lupdate = os.path.join(qt_dir, "bin", "lupdate")
        print(f"== Using lupdate from {lupdate}")
        lupdate_command = f"{lupdate} -extensions cpp,h,qml {client_dir}/src -ts {ts_file_names_str} -no-obsolete"
        print("== Updating from sources")
        try:
            subprocess.run(lupdate_command, shell=True, check=True)
        except subprocess.CalledProcessError:
            print("Lupdate failure")



    print("== Pushing sources")
    os.system("tx push -s")

    print("== Pulling translations")
    os.system("tx pull -af --minimum-perc=1")

    translationFiles = []

    for filename in os.listdir('./translations'):
        translationFiles.append("translations/{0}".format(filename))

    print("== All done you can commit now")

if __name__ == "__main__":
    main()