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

#pragma once

/**
 * Bounds the nesting depth of a re-entrant code path.
 *
 * A Scope created while the depth is below the limit is "entered" and
 * increments the depth for its lifetime. A Scope created once the limit
 * is reached is rejected and leaves the depth unchanged, so callers can
 * bail out instead of recursing further.
 */
class ReentrancyGuard
{
public:
    explicit ReentrancyGuard(int maxDepth)
        : maxDepth_(maxDepth)
    {}

    ReentrancyGuard(const ReentrancyGuard&) = delete;
    ReentrancyGuard& operator=(const ReentrancyGuard&) = delete;

    int depth() const
    {
        return depth_;
    }

    int maxDepth() const
    {
        return maxDepth_;
    }

    class Scope
    {
    public:
        explicit Scope(ReentrancyGuard& guard)
            : guard_(guard)
            , entered_(guard.depth_ < guard.maxDepth_)
        {
            if (entered_)
                ++guard_.depth_;
        }

        ~Scope()
        {
            if (entered_)
                --guard_.depth_;
        }

        Scope(const Scope&) = delete;
        Scope& operator=(const Scope&) = delete;

        bool entered() const
        {
            return entered_;
        }

    private:
        ReentrancyGuard& guard_;
        const bool entered_;
    };

private:
    const int maxDepth_;
    int depth_ {0};
};
