/*
 * Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "app/utils.h"

#include <gtest/gtest.h>

namespace {

QImage
solidImage(const QColor& color, const QSize& size)
{
    QImage image(size, QImage::Format_ARGB32_Premultiplied);
    image.fill(color);
    return image;
}

int
countPixels(const QImage& image, const QColor& color)
{
    int count = 0;
    for (int y = 0; y < image.height(); ++y) {
        for (int x = 0; x < image.width(); ++x) {
            if (image.pixelColor(x, y) == color)
                ++count;
        }
    }
    return count;
}

} // namespace

TEST(GroupAvatarTest, ComposesAllThreeMembers)
{
    const QSize size(90, 90);
    const QColor first(Qt::red);
    const QColor second(Qt::green);
    const QColor third(Qt::blue);

    const auto avatar
        = Utils::composeGroupAvatar({solidImage(first, size), solidImage(second, size), solidImage(third, size)}, size);

    EXPECT_GT(countPixels(avatar, first), 0);
    EXPECT_GT(countPixels(avatar, second), 0);
    EXPECT_GT(countPixels(avatar, third), 0);
}

TEST(GroupAvatarTest, KeepsFourMembersInSeparateCircles)
{
    const QSize size(100, 100);
    const auto avatar = Utils::composeGroupAvatar({solidImage(Qt::red, size),
                                                   solidImage(Qt::green, size),
                                                   solidImage(Qt::blue, size),
                                                   solidImage(Qt::yellow, size)},
                                                  size);

    int opaqueCenterPixels = 0;
    for (int y = size.height() / 2 - 2; y <= size.height() / 2 + 2; ++y) {
        for (int x = size.width() / 2 - 2; x <= size.width() / 2 + 2; ++x) {
            if (qAlpha(avatar.pixel(x, y)) != 0)
                ++opaqueCenterPixels;
        }
    }
    EXPECT_EQ(opaqueCenterPixels, 0);
}
