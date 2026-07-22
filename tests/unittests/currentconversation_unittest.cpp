#include "currentconversation.h"
#include "globaltestenvironment.h"

#include <QMetaObject>

#include <gtest/gtest.h>

TEST(CurrentConversation, HandlesSelectedConversationWithoutCurrentModel)
{
    globalEnv.lrcInstance->set_selectedConvUid("missing-conversation");

    EXPECT_NO_FATAL_FAILURE({
        CurrentConversation currentConversation(globalEnv.lrcInstance.data());
        QMetaObject::invokeMethod(&currentConversation,
                                  "updateErrors",
                                  Qt::DirectConnection,
                                  Q_ARG(QString, QString("missing-conversation")));
    });

    globalEnv.lrcInstance->set_selectedConvUid();
}
