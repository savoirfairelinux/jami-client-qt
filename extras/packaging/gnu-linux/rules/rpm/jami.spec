%define name        jami
%define version     RELEASE_VERSION
%define release     0

# The AppStream 1.0 spec says that the catalog file must be put in /usr/share/swcatalog/xml
# (see https://www.freedesktop.org/software/appstream/docs/chap-CatalogData.html).
#
# However, openSUSE Leap still uses the legacy path /usr/share/app-info/xmls as of version 15.5.
%if 0%{?sle_version} &&  0%{?sle_version} <= 150500
%define appstream_catalog_dir /share/app-info/xmls
%else
%define appstream_catalog_dir /share/swcatalog/xml
%endif

# Exclude vendored Qt6 from dependency generator
%define __requires_exclude ^libQt6.*$

Name:          %{name}
Version:       %{version}
Release:       %{release}%{?dist}
Summary:       Qt client for Jami
Group:         Applications/Internet
License:       GPLv3+
Vendor:        Savoir-faire Linux Inc.
URL:           https://jami.net/
Source:        jami-%{version}.tar.gz
Requires:      jami-daemon = %{version}
Requires:      jami-libqt
Provides:      jami-qt = %{version}
Obsoletes:     jami-qt < 20221010.1109.641d67d-2
Obsoletes:     jami-libclient <= 20220516.0214.9b42ad3-1

# Build dependencies.
%if 0%{?fedora} >= 32
BuildRequires: cmake
BuildRequires: gcc-c++
%endif
BuildRequires: make

# For generating resources.qrc in build time.
BuildRequires: python3

# Build and runtime dependencies.
BuildRequires: qrencode-devel

%description
This package contains the Qt desktop client of Jami. Jami is a free
software for universal communication which respects freedoms and
privacy of its users.

%prep
%setup -n jami-%{version}

%build
# Configure and build bundled ffmpeg (for libavutil/avframe).
mkdir -p %{_builddir}/jami-%{version}/daemon/contrib/native
cd %{_builddir}/jami-%{version}/daemon/contrib/native && \
    ../bootstrap \
        --no-checksums \
        --disable-ogg \
        --disable-flac \
        --disable-vorbis \
        --disable-vorbisenc \
        --disable-speex \
        --disable-sndfile \
        --disable-gsm \
        --disable-speexdsp \
        --disable-natpmp && \
    make list && \
    make fetch && \
    make %{_smp_mflags} V=1 .ffmpeg
# Qt-related variables
export CXXFLAGS="${CXXFLAGS} -fno-lto"
export CFLAGS="${CFLAGS} -fno-lto"
export LDFLAGS="$(CFLAGS) ${LDFLAGS}"
cd %{_builddir}/jami-%{version} && \
    mkdir build && cd build && \
    cmake -DENABLE_LIBWRAP=true \
          -DLIBJAMI_BUILD_DIR=%{_builddir}/jami-%{version}/daemon/src \
          -DCMAKE_INSTALL_PREFIX=%{_prefix} \
          -DCMAKE_INSTALL_LIBDIR=%{_libdir} \
          -DAPPSTREAM_CATALOG_DIR=%{appstream_catalog_dir} \
          -DWITH_DAEMON_SUBMODULE=true \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_VERSION=${BUILD_VERSION} \
          ..
make -C %{_builddir}/jami-%{version}/build %{_smp_mflags} V=2

%install
DESTDIR=%{buildroot} make -C %{_builddir}/jami-%{version}/build install V=2

%files
%defattr(-,root,root,-)
%{_bindir}/jami
%{_datadir}/applications/net.jami.Jami.desktop
%{_datadir}/jami/net.jami.Jami.desktop
%{_datadir}/icons/hicolor/scalable/apps/jami.svg
%{_datadir}/icons/hicolor/48x48/apps/jami.png
%{_datadir}/pixmaps/jami.xpm
%{_datadir}/metainfo/net.jami.Jami.metainfo.xml
%{_prefix}%{appstream_catalog_dir}/jami.xml
%{_datadir}/jami/translations/*
%doc %{_mandir}/man1/jami*
