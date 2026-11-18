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

#include "calloverlaymodel.h"

#include <QSignalSpy>

#include <gtest/gtest.h>

using CallControl::Role;

// The call action bar registers QML actions in a model that outlives them.
// Exposing a destroyed action to QML crashes the JS garbage collector.
TEST(CallControlListModel, ADestroyedActionIsRemovedFromTheModel)
{
    QObject kept;
    CallControlListModel model;
    auto* destroyed = new QObject;
    model.addItem({&kept, true});
    model.addItem({destroyed, true});
    ASSERT_EQ(model.rowCount(), 2);

    QSignalSpy removed(&model, &QAbstractItemModel::rowsRemoved);
    delete destroyed;

    EXPECT_EQ(removed.count(), 1);
    ASSERT_EQ(model.rowCount(), 1);
    EXPECT_EQ(model.data(model.index(0), Role::ItemAction).value<QObject*>(), &kept);
}

TEST(CallControlListModel, ClearingTheModelNotifiesViews)
{
    CallControlListModel model;
    QObject action;
    model.addItem({&action, true});

    QSignalSpy reset(&model, &QAbstractItemModel::modelReset);
    model.clearData();

    EXPECT_EQ(reset.count(), 1);
    EXPECT_EQ(model.rowCount(), 0);
}

TEST(CallControlListModel, AClearedActionDestroyedLaterDoesNotAffectTheModel)
{
    CallControlListModel model;
    auto* stale = new QObject;
    model.addItem({stale, true});
    model.clearData();

    QObject current;
    model.addItem({&current, true});
    delete stale;

    ASSERT_EQ(model.rowCount(), 1);
    EXPECT_EQ(model.data(model.index(0), Role::ItemAction).value<QObject*>(), &current);
}

TEST(CallControlListModel, EnablingAnUnknownActionIsIgnored)
{
    CallControlListModel model;
    QObject action;
    QObject unknown;
    model.addItem({&action, false});

    QSignalSpy reset(&model, &QAbstractItemModel::modelReset);
    model.setEnabled(&unknown, true);
    model.setEnabled(&action, true);

    EXPECT_EQ(reset.count(), 1);
    EXPECT_TRUE(model.data(model.index(0), Role::Enabled).toBool());
}
