#!/usr/bin/env bash
#
# Copyright (C) 2025 Savoir-faire Linux Inc.
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
# This script is used to verfiy and/or update the versions of the dependencies
# used by the daemon in the YAML files of the flathub repo. It does NOT update
# the daemon OR client version in their respective YAML files (jami-daemon.yml and
# jami-client-qt.yml).
#
# This script should be called during the execution of the build-package-flatpak script

# Dependency file names
readonly ARGON2_YAML="argon2.yml"
readonly ASIO_YAML="asio.yml"
readonly DHTNET_YAML="dhtnet.yml"
readonly EXPECTED_LITE_YAML="expected-lite.yml" # Unused
readonly FFMPEG_YAML="ffmpeg.yml"
readonly FFNVCODEC_YAML="ffnvcodec.yml"
readonly FMT_YAML="fmt.yml"
readonly JAMI_DAEMON_YAML="jami-daemon.yml" # dont update
readonly JSONCPP_YAML="jsoncpp.yml"
readonly LIBGIT2_YAML="libgit2.yml"
readonly LIBNATPMP_YAML="libnatpmp.yml"
readonly LIBNOTIFY_YAML="libnotify.yml" # Unused
readonly LIBSECP256K1_YAML="libsecp256k1.yml"
readonly LIBUPNP_YAML="libupnp.yml"
readonly LLHTTP_YAML="llhttp.yml"
readonly MSGPACK_CXX_YAML="msgpack-cxx.yml"
readonly OPENDHT_YAML="opendht.yml"
readonly PJPROJECT_YAML="pjproject.yml"
readonly QRENCODE_YAML="qrencode.yml"
readonly QWINDOWKIT_YAML="qwindowkit.yml"
readonly RESTINIO_YAML="restinio.yml"
readonly SDBUS_CPP_YAML="sdbus-c++.yml"
readonly WEBRTC_AUDIO_PROCESSING_YAML="webrtc-audio-processing.yml"
readonly X264_YAML="x264.yml"
readonly YAML_CPP_YAML="yaml-cpp.yml"

# Directory of sources in contrib system
readonly CONTRIB_SRC_DIR="/home/ierdogan/Documents/jami-client-qt/daemon/contrib/src/"

log()
{
    echo -e "\033[34m$0:\033[0m $1"
}

log_info()
{
    echo -e "\033[33m$0:\033[0m $1"
}

DAEMON_DEPENDENCIES_DIR="../$FLATHUB_REPO_DIR/dependencies"

# Enter the dependencies directory
cd $DAEMON_DEPENDENCIES_DIR

# Variable to hold pattern to be matched
PATTERN_TO_MATCH=""

# Now we update the versions/commits of the dependencies one by one

# Jami-Daemon dependencies
# ARGON2
log "Updating $ARGON2_YAML..."
PATTERN_TO_MATCH="ARGON2_VERSION := "
ARGON2_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/argon2/rules.mak")
log "Found commit: $ARGON2_VERSION"
# Replace current version in the yaml with version found in contrib
sed -i "s|commit: .*|commit: $ARGON2_VERSION|" $ARGON2_YAML

# ASIO
log "Updating $ASIO_YAML..."
PATTERN_TO_MATCH="ASIO_VERSION := "
ASIO_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/asio/rules.mak")
log "Found version: $ASIO_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/chriskohlhoff\/asio\/archive\/$ASIO_VERSION.tar.gz|" $ASIO_YAML
# Update shasum
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/chriskohlhoff\/asio\/archive\/$ASIO_VERSION.tar.gz | sha256sum)|" $ASIO_YAML

# DHTNET
log "Updating $DHTNET_YAML..."
PATTERN_TO_MATCH="DHTNET_VERSION := "
DHTNET_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/dhtnet/rules.mak")
log "Found commit: $DHTNET_VERSION"
sed -i "s|commit: .*|commit: $DHTNET_VERSION|" $DHTNET_YAML

# FFMPEG
log "Updating $FFMPEG_YAML..."
PATTERN_TO_MATCH="FFMPEG_HASH := "
FFMPEG_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/ffmpeg/rules.mak")
log "Found version: $FFMPEG_VERSION"
sed -i "s|url: .*|url: https:\/\/ffmpeg.org\/releases\/ffmpeg-$FFMPEG_VERSION.tar.xz|" $FFMPEG_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/ffmpeg.org\/releases\/ffmpeg-$FFMPEG_VERSION.tar.xz | sha256sum)|" $FFMPEG_YAML

# FFNVCODEC
log "Updating $FFNVCODEC_YAML..."
PATTERN_TO_MATCH="FFNVCODEC_VERSION := "
FFNVCODEC_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/ffnvcodec/rules.mak")
log "Found version: $FFNVCODEC_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/FFmpeg\/nv-codec-headers\/archive\/$FFNVCODEC_VERSION.tar.gz|" $FFNVCODEC_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/FFmpeg\/nv-codec-headers\/archive\/$FFNVCODEC_VERSION.tar.gz | sha256sum)|" $FFNVCODEC_YAML

# FMT
log "Updating $FMT_YAML..."
PATTERN_TO_MATCH="FMT_VERSION := "
FMT_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/fmt/rules.mak")
log "Found version: $FMT_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/fmtlib\/fmt\/archive\/$FMT_VERSION.tar.gz|" $FMT_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/fmtlib\/fmt\/archive\/$FMT_VERSION.tar.gz | sha256sum)|" $FMT_YAML

# JSONCPP
log "Updating $JSONCPP_YAML..."
PATTERN_TO_MATCH="JSONCPP_VERSION := "
JSONCPP_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/jsoncpp/rules.mak")
log "Found version: $JSONCPP_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/open-source-parsers\/jsoncpp\/archive\/$JSONCPP_VERSION.tar.gz|" $JSONCPP_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/open-source-parsers\/jsoncpp\/archive\/$JSONCPP_VERSION.tar.gz | sha256sum)|" $JSONCPP_YAML

# LIBGIT2 - sha
log "Updating $LIBGIT2_YAML..."
PATTERN_TO_MATCH="LIBGIT2_VERSION := "
LIBGIT2_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/libgit2/rules.mak")
log "Found version: $LIBGIT2_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/libgit2\/libgit2\/archive\/v$LIBGIT2_VERSION.tar.gz|" $LIBGIT2_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/libgit2\/libgit2\/archive\/v$LIBGIT2_VERSION.tar.gz | sha256sum)|" $LIBGIT2_YAML

# LIBNATPMP
log "Updating $LIBNATPMP_YAML..."
PATTERN_TO_MATCH="NATPMP_VERSION := "
LIBNATPMP_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/natpmp/rules.mak")
log "Found commit: $LIBNATPMP_VERSION"
sed -i "s|commit: .*|commit: $LIBNATPMP_VERSION|" $LIBNATPMP_YAML

# LIBSECP256K1
log "Updating $LIBSECP256K1_YAML..."
PATTERN_TO_MATCH="SECP256K1_VERSION := "
LIBSECP256K1_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/secp256k1/rules.mak")
log "Found commit: $LIBSECP256K1_VERSION"
sed -i "s|commit: .*|commit: $LIBSECP256K1_VERSION|" $LIBSECP256K1_YAML

# LIBUPNP
log "Updating $LIBUPNP_YAML..."
PATTERN_TO_MATCH="UPNP_VERSION := "
LIBUPNP_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/upnp/rules.mak")
log "Found version: $LIBUPNP_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/pupnp\/pupnp\/archive\/release-$UPNP_VERSION.tar.gz|" $LIBUPNP_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/pupnp\/pupnp\/archive\/release-$UPNP_VERSION.tar.gz | sha256sum)|" $LIBUPNP_YAML

# LLHTTP
log "Updating $LLHTTP_YAML..."
PATTERN_TO_MATCH="LLHTTP_VERSION := "
LLHTTP_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/llhttp/rules.mak")
log "Found version: $LLHTTP_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/nodejs\/llhttp\/archive\/refs\/tags\/release\/v$LLHTTP_VERSION.tar.gz|" $LLHTTP_YAML

# MSGPACK
log "Updating $MSGPACK_CXX_YAML..."
PATTERN_TO_MATCH="MSGPACK_VERSION_NUMBER := "
MSGPACK_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/msgpack/rules.mak")
log "Found version: $MSGPACK_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/msgpack\/msgpack-c\/archive\/cpp-$MSGPACK_VERSION.tar.gz|" $MSGPACK_CXX_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/msgpack\/msgpack-c\/archive\/cpp-$MSGPACK_VERSION.tar.gz | sha256sum)|" $MSGPACK_CXX_YAML

# OPENDHT
log "Updating $OPENDHT_YAML..."
PATTERN_TO_MATCH="OPENDHT_VERSION := "
OPENDHT_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/opendht/rules.mak")
log "Found version: $OPENDHT_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/savoirfairelinux\/opendht\/archive\/v$OPENDHT_VERSION.tar.gz|" $OPENDHT_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/savoirfairelinux\/opendht\/archive\/v$OPENDHT_VERSION.tar.gz | sha256sum)|" $OPENDHT_YAML

# PJPROJECT
log "Updating $PJPROJECT_YAML..."
PATTERN_TO_MATCH="PJPROJECT_VERSION := "
PJPROJECT_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/pjproject/rules.mak")
log "Found version: $PJPROJECT_VERSION"
sed -i "s|commit: .*|commit: $PJPROJECT_VERSION|" $PJPROJECT_YAML

# RESTINIO
log "Updating $RESTINIO_YAML..."
PATTERN_TO_MATCH="RESTINIO_VERSION := "
RESTINIO_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/restinio/rules.mak")
log "Found version: $RESTINIO_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/Stiffstream\/restinio\/releases\/download\/v.$RESTINIO_VERSION\/restinio-$RESTINIO_VERSION.tar.bz2|" $RESTINIO_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/Stiffstream\/restinio\/releases\/download\/v.$RESTINIO_VERSION\/restinio-$RESTINIO_VERSION.tar.bz2 | sha256sum)|" $RESTINIO_YAML

# SDBUS_CPP - sha
log "Updating $SDBUS_CPP_YAML..."
PATTERN_TO_MATCH="SDBUS_CPP_VERSION := "
SDBUS_CPP_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/sdbus-cpp/rules.mak")
log "Found version: $SDBUS_CPP_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/Kistler-Group\/sdbus-cpp\/archive\/refs\/tags\/v$SDBUS_CPP_VERSION.tar.gz|" $SDBUS_CPP_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/Kistler-Group\/sdbus-cpp\/archive\/refs\/tags\/v$SDBUS_CPP_VERSION.tar.gz | sha256sum)|" $SDBUS_CPP_YAML

# WEBRTC_AUDIO_PROCESSING
log "Updating $WEBRTC_AUDIO_PROCESSING_YAML..."
PATTERN_TO_MATCH="WEBRTCAP_VER := "
WEBRTC_AUDIO_PROCESSING_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/webrtc-audio-processing/rules.mak")
log "Found version: $WEBRTC_AUDIO_PROCESSING_VERSION"
sed -i "s|url: .*|url: https:\/\/gitlab.freedesktop.org\/pulseaudio\/webrtc-audio-processing\/-\/archive\/$WEBRTCAP_VER\/webrtc-audio-processing-$WEBRTCAP_VER.tar.gz|" $WEBRTC_AUDIO_PROCESSING_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/gitlab.freedesktop.org\/pulseaudio\/webrtc-audio-processing\/-\/archive\/$WEBRTCAP_VER\/webrtc-audio-processing-$WEBRTCAP_VER.tar.gz | sha256sum)|" $WEBRTC_AUDIO_PROCESSING_YAML

# X264
log "Updating $X264_YAML..."
PATTERN_TO_MATCH="X264_HASH := "
X264_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/x264/rules.mak")
log "Found commit: $X264_VERSION"
sed -i "s|commit: .*|commit: $X264_VERSION|" $X264_YAML

# YAML_CPP
log "Updating $YAML_CPP_YAML..."
PATTERN_TO_MATCH="YAML_CPP_VERSION := "
YAML_CPP_VERSION=$(sed -n -e "s/$PATTERN_TO_MATCH//p" "$CONTRIB_SRC_DIR/yaml-cpp/rules.mak")
log "Found version: $YAML_CPP_VERSION"
sed -i "s|url: .*|url: https:\/\/github.com\/jbeder\/yaml-cpp\/archive\/$YAML_CPP_VERSION.tar.gz|" $YAML_CPP_YAML
sed -i "s|sha256: .*|sha256: $(curl -s https:\/\/github.com\/jbeder\/yaml-cpp\/archive\/$YAML_CPP_VERSION.tar.gz | sha256sum)|" $YAML_CPP_YAML

log_info "The following dependencies are NOT automatically managed: $EXPECTED_LITE_YAML, $LIBNOTIFY_YAML, $QRENCODE_YAML, $QWINDOWKIT_YAML"