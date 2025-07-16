%define name        jami-libqt
%define version     RELEASE_VERSION
%define release     5

# qtwebengine (aka chromium) takes a ton of memory per build process,
# up to 2.3 GiB.  Cap the number of jobs based on the amount of
# available memory to try to guard against OOM build failures.
%define min(a,b) %(echo $(( %1 < %2 ? %1 : %2 )))
%define max(a,b) %(echo $(( %1 > %2 ? %1 : %2 )))

%define cpu_count %max %(nproc) 1
%define available_memory %(free -g | grep -E '^Mem:' | awk '{print $7}')
# Required memory in GiB.
%define max_parallel_builds 4
%define memory_required_per_core 2
%define computed_job_count_ %(echo $(( %available_memory / %memory_required_per_core / %max_parallel_builds )))
%define computed_job_count %max %computed_job_count_ 1
%define job_count %min %cpu_count %computed_job_count
# Exclude vendored Qt6 from dependency generator
%define __provides_exclude_from ^%{_libdir}/qt-jami/.*$
%define __requires_exclude ^libQt6.*$

Name:          %{name}
Version:       %{version}
Release:       %{release}%{?dist}
Summary:       Library for Jami-qt
Group:         Applications/Internet
License:       GPLv3+
Vendor:        Savoir-faire Linux Inc.
URL:           https://jami.net/
Source:        jami-libqt-%{version}.tar.xz
Patch0:        0001-qtwebengine-fix-build-error-due-to-missing-chromium-dependency.patch
Patch1:        0002-qtwebengine-fix-ASSERT_TRIVIALLY_COPYABLE-failure.patch
Patch2:        0003-qtwebengine-add-missing-zygote-dependency.patch

%global gst 0.10
%if 0%{?fedora} || 0%{?rhel} > 7
%global gst 1.0
%endif

# Build dependencies
BuildRequires: autoconf
BuildRequires: make
# QtWebEngine
BuildRequires: bison
BuildRequires: gperf
BuildRequires: flex
BuildRequires: vulkan-devel
%if %{defined suse_version}
BuildRequires: ffmpeg-devel
BuildRequires: ffmpeg
BuildRequires: python-xml
BuildRequires: mozilla-nss-devel
%else
BuildRequires: python-six
BuildRequires: pkgconfig(gstreamer-%{gst})
BuildRequires: pkgconfig(gstreamer-app-%{gst})
BuildRequires: pkgconfig(gstreamer-audio-%{gst})
BuildRequires: pkgconfig(gstreamer-base-%{gst})
BuildRequires: pkgconfig(gstreamer-pbutils-%{gst})
BuildRequires: pkgconfig(gstreamer-plugins-bad-%{gst})
BuildRequires: pkgconfig(gstreamer-video-%{gst})
%endif

%description
This package contains Qt libraries for Jami.

%prep
%setup -n qt-everywhere-src-%{version}
%patch -P 0 -p1
%patch -P 1 -p1
%patch -P 2 -p1

%build
echo "Building Qt using %{job_count} parallel jobs"

# recent gcc version do not like lto from qt
CXXFLAGS="${CXXFLAGS} -fno-lto" CFLAGS="${CFLAGS} -fno-lto" LDFLAGS="$(CFLAGS) ${LDFLAGS}" ./configure \
  -opensource \
  -confirm-license \
  -nomake examples \
  -nomake tests \
  -prefix "%{_libdir}/qt-jami"
# Chromium is built using Ninja, which doesn't honor MAKEFLAGS.
cmake --build . --parallel

%install
cmake --install . --prefix %{buildroot}/${QT_JAMI_PREFIX}

%files
%defattr(-,root,root,-)
%{_libdir}/qt-jami
