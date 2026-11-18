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

// The call controls are QML Actions owned by the call action bar. When the bar
// goes away the model must not keep handing their addresses to QML: wrapping a
// freed QObject crashes the JS garbage collector on its next pass.
TEST(CallControlListModel, ADestroyedActionLeavesTheModel)
{
    CallControlListModel model;
    auto* kept = new QObject;
    auto* destroyed = new QObject;
    model.addItem({kept, true});
    model.addItem({destroyed, true});
    ASSERT_EQ(model.rowCount(), 2);

    delete destroyed;

    ASSERT_EQ(model.rowCount(), 1);
    EXPECT_EQ(model.data(model.index(0, 0), CallControl::Role::ItemAction).value<QObject*>(), kept);
    delete kept;
    EXPECT_EQ(model.rowCount(), 0);
}

TEST(CallControlListModel, ClearingTheControlsResetsTheModel)
{
    CallControlListModel model;
    QObject action;
    model.addItem({&action, true});
    QSignalSpy reset(&model, &QAbstractItemModel::modelReset);

    model.clearData();

    EXPECT_EQ(model.rowCount(), 0);
    EXPECT_EQ(reset.count(), 1);
}

TEST(CallControlListModel, EnablingAnUnknownActionKeepsTheModelUsable)
{
    CallControlListModel model;
    QObject action;
    QObject unknown;
    model.addItem({&action, true});

    model.setEnabled(&unknown, false);
    model.setEnabled(&action, false);

    ASSERT_EQ(model.rowCount(), 1);
    EXPECT_FALSE(model.data(model.index(0, 0), CallControl::Role::Enabled).toBool());
}
