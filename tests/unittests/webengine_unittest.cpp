#include "utils.h"

#include <gtest/gtest.h>

TEST(WebEngineSupport, RejectsWindowsVersionsOlderThanTen)
{
    EXPECT_FALSE(Utils::isSupportedWebEngineWindowsVersion(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 6, 2)));
    EXPECT_FALSE(Utils::isSupportedWebEngineWindowsVersion(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 6, 3)));
}

TEST(WebEngineSupport, AcceptsWindowsTenAndLater)
{
    EXPECT_TRUE(Utils::isSupportedWebEngineWindowsVersion(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 10, 0)));
    EXPECT_TRUE(Utils::isSupportedWebEngineWindowsVersion(
        QOperatingSystemVersion(QOperatingSystemVersion::Windows, 11, 0)));
}

TEST(WebEngineSupport, AcceptsNonWindowsVersions)
{
    EXPECT_TRUE(Utils::isSupportedWebEngineWindowsVersion(
        QOperatingSystemVersion(QOperatingSystemVersion::MacOS, 10, 15)));
}
