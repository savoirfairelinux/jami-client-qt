# -*- mode: makefile; -*-
# Copyright (C) 2016-2024 Savoir-faire Linux Inc.
#
# Author: Maxim Cournoyer <maxim.cournoyer@savoirfairelinux.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
.DEFAULT_GOAL := package-all

# Default caching directory
export TARBALLS ?= /var/cache/jami

##############################
## Version number variables ##
##############################
TARBALL_VERSION := $(shell cat $(CURDIR)/.tarball-version 2> /dev/null)

ifeq ($(TARBALL_VERSION),)
RELEASE_VERSION := $(shell ./extras/packaging/gnu-linux/scripts/release-version.sh)
else
$(warning Using version from the .tarball-version file: $(TARBALL_VERSION))
RELEASE_VERSION := $(TARBALL_VERSION)
endif
RELEASE_DIRNAME := jami-$(RELEASE_VERSION)
RELEASE_TARBALL_FILENAME := $(RELEASE_DIRNAME).tar.gz

# Export for consumption in child processes.
export RELEASE_VERSION
export RELEASE_DIRNAME
export RELEASE_TARBALL_FILENAME

# Debian versions
DEBIAN_VERSION := $(RELEASE_VERSION)~dfsg1-1
DEBIAN_DSC_FILENAME := jami_$(DEBIAN_VERSION).dsc

# Qt versions
QT_MAJOR := 6
QT_MINOR := 6
QT_PATCH := 1
QT_TARBALL_CHECKSUM := dd3668f65645fe270bc615d748bd4dc048bd17b9dc297025106e6ecc419ab95d
DEBIAN_QT_VERSION := $(QT_MAJOR).$(QT_MINOR).$(QT_PATCH)-0
DEBIAN_QT_DSC_FILENAME := libqt-jami_$(DEBIAN_QT_VERSION).dsc
QT_JAMI_PREFIX := /usr/lib/libqt-jami

#####################
## Other variables ##
#####################
TMPDIR := $(shell mktemp -d)
CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

#############################
## Release tarball targets ##
#############################
.PHONY: release-tarball purge-release-tarballs portable-release-tarball
# See: https://reproducible-builds.org/docs/archives/
TAR_REPRODUCIBILITY_OPTIONS = \
	--format=gnu \
	--mtime=@1 \
	--owner=root:0 \
	--group=root:0

# This file can be used when not wanting to invoke the tarball
# producing machinery (which depends on the Git checkout), nor its
# prerequisites.  It is used to set the TARBALL_VERSION Make variable.
.tarball-version:
	echo $(RELEASE_VERSION) > $@

purge-release-tarballs:
	rm -f jami-*.tar.* tarballs.manifest

release-tarball:
	$(MAKE) -f extras/packaging/gnu-linux/Makefile "$(RELEASE_TARBALL_FILENAME)"

# Predicate to check if the 'guix' command is available.
has-guix-p:
	command -v guix > /dev/null 2>&1 || \
	  (echo 'guix' is required to build the '$@' target && exit 1)

# The bundled tarballs included in the release tarball depend on what
# is available on the host.  To ensure it can be shared across all
# different GNU/Linux distributions, generate it in a minimal
# container.  Wget uses GnuTLS, which looks up its certs from
# /etc/ssl/certs.
guix-share-tarball-arg = $${TARBALLS:+"--share=$$TARBALLS"}
portable-release-tarball: has-guix-p
	guix shell --container --network \
          --preserve=TARBALLS $(guix-share-tarball-arg) \
          --symlink=/usr/bin/env=bin/env \
          --symlink=/etc/ssl/certs=etc/ssl/certs \
          --manifest=extras/packaging/gnu-linux/guix/minimal-manifest.scm \
          -- $(MAKE) -f extras/packaging/gnu-linux/Makefile release-tarball

daemon/contrib/native/Makefile:
	mkdir -p ./daemon/contrib/native && \
	cd daemon/contrib/native && \
	../bootstrap

# Fetch the required contrib sources and copy them to
# daemon/contrib/tarballs.  To use a custom tarballs cache directory,
# export the TARBALLS environment variable.
tarballs.manifest: daemon/contrib/native/Makefile
	cd daemon/contrib/native && \
	$(MAKE) list && \
	$(MAKE) fetch -j && \
	$(MAKE) --no-print-directory --silent list-tarballs > "$(CURDIR)/$@"

ifeq ($(TARBALL_VERSION),)
# Generate the release tarball.  To regenerate a fresh tarball
# manually clear the tarballs.manifest file.
$(RELEASE_TARBALL_FILENAME): tarballs.manifest
# Prepare the sources of the top repository and relevant submodules.
	rm -f "$@"
	mkdir $(TMPDIR)/$(RELEASE_DIRNAME)
	git archive HEAD | tar xf - -C $(TMPDIR)/$(RELEASE_DIRNAME)
	for m in \
	    ./daemon \
	    . \
	    ./3rdparty/SortFilterProxyModel \
	    ./3rdparty/md4c \
	    ./3rdparty/tidy-html5; do \
	  (cd "$$m" && git archive --prefix "$$m/" HEAD \
	    | tar xf - -C $(TMPDIR)/$(RELEASE_DIRNAME)); \
	done
# Create the base archive.
	tar -cf $(TMPDIR)/$(RELEASE_DIRNAME).tar $(TMPDIR)/$(RELEASE_DIRNAME) \
	  --transform "s,.*/$(RELEASE_DIRNAME),$(RELEASE_DIRNAME)," \
	  $(TAR_REPRODUCIBILITY_OPTIONS)
# Append the cached tarballs listed in the manifest.
	tar --append --file $(TMPDIR)/$(RELEASE_DIRNAME).tar \
	  --files-from $< \
	  --transform "s,^.*/,$(RELEASE_DIRNAME)/daemon/contrib/tarballs/," \
        $(TAR_REPRODUCIBILITY_OPTIONS)
# Compress the tarball and move it into place.
	gzip --no-name $(TMPDIR)/$(RELEASE_DIRNAME).tar
	mv $(TMPDIR)/$(RELEASE_DIRNAME).tar.gz "$@"
	rm -rf $(TMPDIR)
else
# If TARBALL_VERSION is defined, assume it's already been generated,
# without doing any checks, which would require Git.
$(RELEASE_TARBALL_FILENAME):
endif

#######################
## Packaging targets ##
#######################

#
# Traditionally built packages (in Docker containers).
#
DISTRIBUTIONS := \
	debian_11 \
	debian_12 \
	debian_testing \
	debian_unstable \
	ubuntu_20.04 \
	ubuntu_22.04 \
	ubuntu_23.04 \
	ubuntu_23.10 \
	fedora_37 \
	fedora_38 \
	fedora_39 \
	alma_9 \
	opensuse-leap_15.4 \
	opensuse-leap_15.5 \
	snap

IS_SHELL_INTERACTIVE := $(shell [ -t 0 ] && echo yes)

# The following Make variable can be used to provide extra arguments
# used with the 'docker run' commands invoked to build the packages.
DOCKER_RUN_EXTRA_ARGS =

# This function is used to produce the rules of the packaging targets
# that rely on Docker.
# Arg1: The name-version string of the distribution (e.g., ubuntu-18.04).
# Arg2: Extra arguments to pass to 'docker build'.
# Arg3: Extra arguments to pass to 'docker run'.
define make-docker-package-target
$(1)-docker-image-name := jami-packaging-$(1)
$(1)-docker-image-file := .docker-image-$$($(1)-docker-image-name)
$(1)-docker-run-command := docker run \
  --rm --privileged --security-opt apparmor=docker-default \
  -e RELEASE_VERSION="$(RELEASE_VERSION)" \
  -e RELEASE_DIRNAME="$(RELEASE_DIRNAME)" \
  -e RELEASE_TARBALL_FILENAME="$(RELEASE_TARBALL_FILENAME)" \
  -e DEBIAN_VERSION="$(DEBIAN_VERSION)" \
  -e DEBIAN_QT_VERSION="$(DEBIAN_QT_VERSION)" \
  -e CURRENT_UID="$(CURRENT_UID)" \
  -e CURRENT_GID="$(CURRENT_GID)" \
  -e DISTRIBUTION="$(1)" \
  -e QT_JAMI_PREFIX="$(QT_JAMI_PREFIX)" \
  -e QT_MAJOR="$(QT_MAJOR)" \
  -e QT_MINOR="$(QT_MINOR)" \
  -e QT_PATCH="$(QT_PATCH)" \
  -e QT_TARBALL_CHECKSUM="$(QT_TARBALL_CHECKSUM)" \
  -e FORCE_REBUILD_QT="$(FORCE_REBUILD_QT)" \
  -e SNAP_PKG_NAME="$(or $(SNAP_PKG_NAME),jami)" \
  -e TARBALLS="$(TARBALLS)" \
  -v '$(TARBALLS)':'$(TARBALLS)' \
  -v '$(CURDIR)/$(RELEASE_TARBALL_FILENAME)':'/src/$(RELEASE_TARBALL_FILENAME)' \
  -v '$(CURDIR)/extras/packaging/gnu-linux/packages/$(1)':/opt/output \
  -t $(and $(IS_SHELL_INTERACTIVE),-i) \
  $(3) \
  "$$($(1)-docker-image-name)"

$$($(1)-docker-image-file): extras/packaging/gnu-linux/docker/Dockerfile_$(1)
	docker build \
	  -t $$($(1)-docker-image-name) \
	  -f extras/packaging/gnu-linux/docker/Dockerfile_$(1) $(2) $(CURDIR) && \
	touch "$$@"

extras/packaging/gnu-linux/packages/$(1)/.packages-built: $(RELEASE_TARBALL_FILENAME) $$($(1)-docker-image-file)
	mkdir -p "$$$$(dirname "$$@")" && \
	$$($(1)-docker-run-command) && \
	touch "$$@"

.PHONY: $(1)
$(1): extras/packaging/gnu-linux/packages/$(1)/.packages-built
PACKAGE-TARGETS += $(1)

.PHONY: $(1)-interactive
$(1)-interactive: $(RELEASE_TARBALL_FILENAME) $$($(1)-docker-image-file)
	$$($(1)-docker-run-command) bash

endef

$(foreach target,$(DISTRIBUTIONS),\
	$(eval $(call make-docker-package-target,$(target))))

#
# Guix-generated Debian packages (deb packs) targets.
#
SUPPORTED_GNU_ARCHS = x86_64
GUIX_PACK_FORMATS = deb rpm

# TODO: Add a postin script for the RPM pack.
# Arg1: the 'guix pack' format to use, e.g. 'deb' or 'rpm'.
define guix-pack-command
guix pack -C xz -f $(1) -m $(CURDIR)/extras/packaging/gnu-linux/guix/guix-pack-manifest.scm -v3 \
  -S /usr/bin/jami=bin/jami \
  -S /usr/share/applications/jami.desktop=share/applications/jami.desktop \
  -S /usr/share/icons/hicolor/scalable/apps/jami.svg=share/icons/hicolor/scalable/apps/jami.svg \
  -S /usr/share/icons/hicolor/48x48/apps/jami.png=share/icons/hicolor/48x48/apps/jami.png \
  -S /usr/share/metainfo/jami.appdata.xml=share/metainfo/jami.appdata.xml \
  $(and $(findstring deb,$(1)), \
    --postinst-file=$(CURDIR)/extras/packaging/gnu-linux/guix/guix-pack-deb.postinst)
endef

# Arg1: the 'guix pack' format to use, e.g. 'deb' or 'rpm'.
# Arg2: the GNU architecture type (e.g., x86_64, i686, powerpcle, etc.)
define define-guix-pack-rule
$(1)-file-name := extras/packaging/gnu-linux/packages/guix-$(1)-pack/jami-$(RELEASE_VERSION)-$(2).$(1)
PACKAGE-TARGETS += $(1)-pack-$(subst _,-,$(2))
.PHONY: $(1)-pack-$(subst _,-,$(2))
$(1)-pack-$(subst _,-,$(2)): $$($(1)-file-name)
$$($(1)-file-name): has-guix-p $(RELEASE_TARBALL_FILENAME)
	output=$$$$($(call guix-pack-command,$(1)) --system=$(2)-linux $$(GUIX_PACK_ARGS)) && \
	mkdir -p "$$$$(dirname "$$@")" && \
	cp --reflink=auto "$$$$output" "$$@" && \
	guix gc --delete "$$$$output"
	chmod +w "$$@"
endef

$(foreach format,$(GUIX_PACK_FORMATS),\
  $(foreach arch,$(SUPPORTED_GNU_ARCHS),\
    $(eval $(call define-guix-pack-rule,$(format),$(arch)))))

package-all: $(PACKAGE-TARGETS)

.PHONY: list-package-targets
list-package-targets:
	@$(foreach p,$(sort $(PACKAGE-TARGETS)),\
		echo $(p);)

###################
## Other targets ##
###################
.PHONY: docs

# Build the documentation
# Note that newly added RST files will likely not display on all documents'
# navigation bar unless the docs/build folder is manually deleted.
docs: env
	env/bin/sphinx-build -b html docs/source docs/build/html
	env/bin/sphinx-build -b texinfo docs/source docs/build/texinfo

env:
	virtualenv env
	env/bin/pip install Sphinx==1.4.1 sphinx-rtd-theme==0.1.9

.PHONY: clean
clean:
	rm -rf env
	rm -rf docs/build
	rm -f jami-*.tar.gz
	rm -rf extras/packaging/gnu-linux/packages
	rm -f .docker-image-*
	rm -rf daemon/contrib/tarballs/*
