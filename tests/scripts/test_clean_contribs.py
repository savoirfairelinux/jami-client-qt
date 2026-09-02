# test_clean_contribs.py --- Regression tests for build.py's clean_contribs()

# Copyright (C) 2016-2026 Savoir-faire Linux Inc.
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

import importlib.util
import os
import sys
import tempfile
import unittest
from unittest import mock

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ABI_TRIPLET = 'x86_64-linux-gnu'


def load_build_module():
    path = os.path.join(REPO_ROOT, 'build.py')
    spec = importlib.util.spec_from_file_location('jami_build', path)
    module = importlib.util.module_from_spec(spec)
    # Keep the import from dropping a __pycache__ next to build.py.
    dont_write_bytecode = sys.dont_write_bytecode
    sys.dont_write_bytecode = True
    try:
        spec.loader.exec_module(module)
    finally:
        sys.dont_write_bytecode = dont_write_bytecode
    return module


def touch(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write('')


class CleanContribsTest(unittest.TestCase):
    """clean_contribs() must leave no trace of the contribs it is asked to clean.

    A leftover source directory is not harmless: the contrib makefiles treat an
    existing directory as an already extracted tarball and skip extraction, so
    the next build runs ./configure in an empty tree and fails.
    """

    def setUp(self):
        self.module = load_build_module()
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

        cwd = os.getcwd()
        self.addCleanup(os.chdir, cwd)
        os.chdir(self.tmp.name)

        self.contrib = os.path.join(self.tmp.name, 'daemon', 'contrib')
        self.build = os.path.join(self.contrib, 'build-' + ABI_TRIPLET)
        self.prefix = os.path.join(self.contrib, ABI_TRIPLET)

        # Two contribs, so the test also covers contribs beyond the first one.
        for name in ('ffmpeg', 'pjproject'):
            touch(os.path.join(self.build, name, 'configure'))
            # Tarballs ship dotfiles; a glob-based removal misses them.
            touch(os.path.join(self.build, name, '.mailmap'))
            touch(os.path.join(self.build, '.' + name))

        touch(os.path.join(self.prefix, 'lib', 'libavcodec.a'))
        touch(os.path.join(self.prefix, 'lib', 'libpj.a'))
        touch(os.path.join(self.prefix, 'include', 'libavutil', 'avutil.h'))
        touch(os.path.join(self.prefix, 'include', 'pjlib.h'))
        touch(os.path.join(self.contrib, 'tarballs', 'ffmpeg-6.1.3.tar.xz'))
        touch(os.path.join(self.contrib, 'tarballs', 'pjproject-2.15.tar.gz'))

    def assert_contrib_cleaned(self, name):
        source_dir = os.path.join(self.build, name)
        self.assertFalse(os.path.exists(source_dir),
                         f'{name}: source directory still present')
        self.assertFalse(os.path.exists(os.path.join(self.build, '.' + name)),
                         f'{name}: build stamp still present')

    def test_clean_all_removes_every_contrib(self):
        self.module.clean_contribs(['all'])

        for name in ('ffmpeg', 'pjproject'):
            self.assert_contrib_cleaned(name)

        self.assertEqual(os.listdir(os.path.join(self.contrib, 'tarballs')), [],
                         'tarballs were not removed')
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'lib', 'libavcodec.a')))
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'lib', 'libpj.a')))
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'include', 'libavutil')))
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'include', 'pjlib.h')))

    def test_clean_named_contrib_leaves_the_others_alone(self):
        self.module.clean_contribs(['ffmpeg'])

        self.assert_contrib_cleaned('ffmpeg')
        # The install prefix must be cleaned too: 'build-<triplet>' matches the
        # triplet pattern as well, and picking it would silently leave the built
        # libraries and headers in place.
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'lib', 'libavcodec.a')),
                         'ffmpeg libraries were left in the install prefix')
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'include', 'libavutil')))

        self.assertTrue(os.path.exists(os.path.join(self.build, 'pjproject', 'configure')),
                        'pjproject was cleaned but was not requested')
        self.assertTrue(os.path.exists(os.path.join(self.build, '.pjproject')))
        self.assertTrue(os.path.exists(os.path.join(self.prefix, 'lib', 'libpj.a')))

    def test_install_prefix_is_preferred_over_the_build_directory(self):
        """'build-<triplet>' matches the triplet pattern as well.

        Which of the two directories os.listdir() yields first is arbitrary, so
        pin the order that picks the build directory: the install prefix must
        still be the one that gets cleaned.
        """
        real_listdir = os.listdir

        def build_dir_first(path):
            entries = real_listdir(path)
            if os.path.abspath(path) == os.path.abspath(self.contrib):
                entries.sort(key=lambda name: (not name.startswith('build'), name))
            return entries

        with mock.patch('os.listdir', side_effect=build_dir_first):
            self.module.clean_contribs(['ffmpeg'])

        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'lib', 'libavcodec.a')),
                         'ffmpeg libraries were left in the install prefix')
        self.assertFalse(os.path.exists(os.path.join(self.prefix, 'include', 'libavutil')))


if __name__ == '__main__':
    unittest.main()
