/****************************************************************************
 *   Copyright (C) 2017-2026 Savoir-faire Linux Inc.                        *
 *                                                                          *
 *   This library is free software; you can redistribute it and/or          *
 *   modify it under the terms of the GNU Lesser General Public             *
 *   License as published by the Free Software Foundation; either           *
 *   version 2.1 of the License, or (at your option) any later version.     *
 *                                                                          *
 *   This library is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU      *
 *   Lesser General Public License for more details.                        *
 *                                                                          *
 *   You should have received a copy of the GNU General Public License      *
 *   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
 ***************************************************************************/
#include "database.h"

#include "api/interaction.h"

#include <account_const.h>

// Lrc for migrations
#include "dbus/configurationmanager.h"
#include "vcard.h"
#include <account_const.h>

#include <QObject>
#include <QtCore/QDir>
#include <QtCore/QDebug>
#include <QtCore/QFile>
#include <QtCore/QJsonArray>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlError>
#include <QtSql/QSqlRecord>
#include <QtCore/QVariant>
#include <QDir>
#include <QTextStream>

#include <sstream>
#include <stdexcept>

namespace lrc {

using namespace api;

Database::Database(const QString& name, const QString& basePath)
    : QObject()
    , connectionName_(name)
    , basePath_(basePath)
    , version_(DB_VERSION)
{
    if (not QSqlDatabase::drivers().contains("QSQLITE")) {
        throw std::runtime_error("QSQLITE not supported");
    }

    // initalize the database.
    db_ = QSqlDatabase::addDatabase("QSQLITE", connectionName_);

    auto databaseFile = QFileInfo(basePath_ + connectionName_ + ".db");
    QString databaseFileName = databaseFile.fileName();
    auto absoluteDir = databaseFile.absoluteDir();

    // make sure the directory exists
    if (!absoluteDir.exists())
        absoluteDir.mkpath(".");
    databaseFullPath_ = absoluteDir.filePath(databaseFileName);

    db_.setDatabaseName(databaseFullPath_);
}

Database::~Database()
{
    close();
}

void
Database::close()
{
    // close db
    if (db_.isOpen()) {
        db_.close();
    }
}

void
Database::remove()
{
    // close db and remove file
    close();
    QFile(databaseFullPath_).remove();
}

void
Database::load()
{
    // open the database.
    if (not db_.open()) {
        std::stringstream ss;
        ss << "Unable to open database: " << connectionName_.toStdString();
        throw std::runtime_error(ss.str());
    }

    // if db is empty we create them.
    if (db_.tables().empty()) {
        try {
            QSqlDatabase::database(connectionName_).transaction();
            createTables();
            QSqlDatabase::database(connectionName_).commit();
        } catch (QueryError& e) {
            QSqlDatabase::database(connectionName_).rollback();
            throw std::runtime_error("An error occurred while creating the database.");
        }
    } else {
        migrateIfNeeded();
    }
}

void
Database::createTables()
{
    QSqlQuery query(db_);

    auto tableConversations = "CREATE TABLE conversations ( \
                                    id INTEGER, \
                                    participant TEXT, \
                                    extra_data TEXT \
                                )";

    auto indexConversations = "CREATE INDEX `idx_conversations_uri` ON `conversations` (`participant`)";

    auto tableInteractions = "CREATE TABLE interactions ( \
                                    id INTEGER PRIMARY KEY, \
                                    author TEXT, \
                                    conversation INTEGER, \
                                    timestamp INTEGER, \
                                    body TEXT, \
                                    type TEXT, \
                                    status TEXT, \
                                    is_read INTEGER, \
                                    daemon_id BIGINT, \
                                    extra_data TEXT, \
                                    FOREIGN KEY(conversation) REFERENCES conversations(id) \
                                )";

    auto indexInteractions = "CREATE INDEX `idx_interactions_uri` ON `interactions` (`author`)";

    // add conversations table
    if (!db_.tables().contains("conversations", Qt::CaseInsensitive)) {
        if (!query.exec(tableConversations) || !query.exec(indexConversations)) {
            throw QueryError(std::move(query));
        }
    }

    // add interactions table
    if (!db_.tables().contains("interactions", Qt::CaseInsensitive)) {
        if (!query.exec(tableInteractions) || !query.exec(indexInteractions)) {
            throw QueryError(std::move(query));
        }
    }

    storeVersion(version_);
}

void
Database::migrateIfNeeded()
{
    try {
        auto currentVersion = getVersion();
        if (currentVersion == version_) {
            return;
        }
        QSqlDatabase::database().transaction();
        migrateFromVersion(currentVersion);
        storeVersion(version_);
        QSqlDatabase::database().commit();
    } catch (QueryError& e) {
        QSqlDatabase::database().rollback();
        throw std::runtime_error("An error occurred while migrating the database");
    }
}

void
Database::migrateFromVersion(const QString& currentVersion)
{
    // If we ever have a new version, we can migrate the database here.
    LC_WARN << "Database migration from version " << currentVersion << " to " << version_ << " not implemented.";
}

void
Database::storeVersion(const QString& version)
{
    QSqlQuery query(db_);

    auto storeVersionQuery = "PRAGMA user_version = " + version;

    if (not query.exec(storeVersionQuery))
        throw QueryError(std::move(query));

    qDebug() << "database " << databaseFullPath_ << " version set to:" << version;
}

QString
Database::getVersion()
{
    QSqlQuery query(db_);
    auto getVersionQuery = "pragma user_version";
    if (not query.exec(getVersionQuery))
        throw QueryError(std::move(query));
    query.first();
    return query.value(0).toString();
}

QString
Database::insertInto(
    const QString& table,            // "tests"
    const MapStringString& bindCol,  // {{":id", "id"}, {":forename", "colforname"}, {":name", "colname"}}
    const MapStringString& bindsSet) // {{":id", "7"}, {":forename", "alice"}, {":name", "cooper"}}
{
    QSqlQuery query(db_);
    QString columns;
    QString binds;

    for (const auto& entry : bindCol.toStdMap()) {
        columns += entry.second + ",";
        binds += entry.first + ",";
    }

    // remove the last ','
    columns.chop(1);
    binds.chop(1);

    auto prepareStr = "INSERT INTO " + table + " (" + columns + ") VALUES (" + binds + ")";
    query.prepare(prepareStr);

    for (const auto& entry : bindsSet.toStdMap())
        query.bindValue(entry.first, entry.second);

    if (not query.exec())
        throw QueryInsertError(std::move(query), table, bindCol, bindsSet);

    if (not query.exec("SELECT last_insert_rowid()"))
        throw QueryInsertError(std::move(query), table, bindCol, bindsSet);

    if (!query.next())
        return QString::number(-1);
    ;

    return query.value(0).toString();
}

void
Database::update(const QString& table,              // "tests"
                 const QString& set,                // "location=:place, phone:=nmbr"
                 const MapStringString& bindsSet,   // {{":place", "montreal"}, {":nmbr", "514"}}
                 const QString& where,              // "contact=:name AND id=:id
                 const MapStringString& bindsWhere) // {{":name", "toto"}, {":id", "65"}}
{
    QSqlQuery query(db_);

    auto prepareStr = QString("UPDATE " + table + " SET " + set + " WHERE " + where);
    query.prepare(prepareStr);

    for (const auto& entry : bindsSet.toStdMap())
        query.bindValue(entry.first, entry.second);

    for (const auto& entry : bindsWhere.toStdMap())
        query.bindValue(entry.first, entry.second);

    if (not query.exec())
        throw QueryUpdateError(std::move(query), table, set, bindsSet, where, bindsWhere);
}

Database::Result
Database::select(const QString& select,             // "id", "body", ...
                 const QString& table,              // "tests"
                 const QString& where,              // "contact=:name AND id=:id
                 const MapStringString& bindsWhere) // {{":name", "toto"}, {":id", "65"}}
{
    QSqlQuery query(db_);
    QString columnsSelect;

    auto prepareStr = QString("SELECT " + select + " FROM " + table + (where.isEmpty() ? "" : (" WHERE " + where)));
    query.prepare(prepareStr);

    for (const auto& entry : bindsWhere.toStdMap())
        query.bindValue(entry.first, entry.second);

    if (not query.exec())
        throw QuerySelectError(std::move(query), select, table, where, bindsWhere);

    QSqlRecord rec = query.record();
    const auto col_num = rec.count();
    Database::Result result = {col_num, {}};

    // for each row
    while (query.next()) {
        for (int i = 0; i < col_num; i++)
            result.payloads.push_back(query.value(i).toString());
    }

    return result;
}

int
Database::count(const QString& count,              // "id", "body", ...
                const QString& table,              // "tests"
                const QString& where,              // "contact=:name AND id=:id"
                const MapStringString& bindsWhere) // {{":name", "toto"}, {":id", "65"}}
{
    QSqlQuery query(db_);
    QString columnsSelect;
    auto prepareStr = QString("SELECT count(" + count + ") FROM " + table + " WHERE " + where);
    query.prepare(prepareStr);

    for (const auto& entry : bindsWhere.toStdMap())
        query.bindValue(entry.first, entry.second);

    if (not query.exec())
        throw QueryError(std::move(query));

    query.next();
    return query.value(0).toInt();
}

void
Database::deleteFrom(const QString& table,              // "tests"
                     const QString& where,              // "contact=:name AND id=:id
                     const MapStringString& bindsWhere) // {{":name", "toto"}, {":id", "65"}}
{
    QSqlQuery query(db_);

    auto prepareStr = QString("DELETE FROM " + table + " WHERE " + where);
    query.prepare(prepareStr);

    for (const auto& entry : bindsWhere.toStdMap())
        query.bindValue(entry.first, entry.second);

    if (not query.exec())
        throw QueryDeleteError(std::move(query), table, where, bindsWhere);
}

Database::QueryError::QueryError(QSqlQuery&& query)
    : std::runtime_error(query.lastError().text().toStdString())
    , query(std::move(query))
{}

Database::QueryInsertError::QueryInsertError(QSqlQuery&& query,
                                             const QString& table,
                                             const MapStringString& bindCol,
                                             const MapStringString& bindsSet)
    : QueryError(std::move(query))
    , table(table)
    , bindCol(bindCol)
    , bindsSet(bindsSet)
{}

QString
Database::QueryInsertError::details()
{
    QTextStream qts;
    qts << "parameters sent :";
    qts << "table = " << table;
    for (auto& b : bindCol.toStdMap())
        qts << "   {" << b.first << "}, {" << b.second << "}";
    for (auto& b : bindsSet.toStdMap())
        qts << "   {" << b.first << "}, {" << b.second << "}";
    return qts.readAll();
}

Database::QueryUpdateError::QueryUpdateError(QSqlQuery&& query,
                                             const QString& table,
                                             const QString& set,
                                             const MapStringString& bindsSet,
                                             const QString& where,
                                             const MapStringString& bindsWhere)
    : QueryError(std::move(query))
    , table(table)
    , set(set)
    , bindsSet(bindsSet)
    , where(where)
    , bindsWhere(bindsWhere)
{}

QString
Database::QueryUpdateError::details()
{
    QTextStream qts;
    qts << "parameters sent :";
    qts << "table = " << table;
    qts << "set = " << set;
    qts << "bindsSet :";
    for (auto& b : bindsSet.toStdMap())
        qts << "   {" << b.first << "}, {" << b.second << "}";
    qts << "where = " << where;
    qts << "bindsWhere :";
    for (auto& b : bindsWhere.toStdMap())
        qts << "   {" << b.first << "}, {" << b.second << "}";
    return qts.readAll();
}

Database::QuerySelectError::QuerySelectError(QSqlQuery&& query,
                                             const QString& select,
                                             const QString& table,
                                             const QString& where,
                                             const MapStringString& bindsWhere)
    : QueryError(std::move(query))
    , select(select)
    , table(table)
    , where(where)
    , bindsWhere(bindsWhere)
{}

QString
Database::QuerySelectError::details()
{
    QTextStream qts;
    qts << "parameters sent :";
    qts << "select = " << select;
    qts << "table = " << table;
    qts << "where = " << where;
    qts << "bindsWhere :";
    for (auto& b : bindsWhere.toStdMap())
        qts << "   {" << b.first << "}, {" << b.second << "}";
    return qts.readAll();
}

Database::QueryDeleteError::QueryDeleteError(QSqlQuery&& query,
                                             const QString& table,
                                             const QString& where,
                                             const MapStringString& bindsWhere)
    : QueryError(std::move(query))
    , table(table)
    , where(where)
    , bindsWhere(bindsWhere)
{}

QString
Database::QueryDeleteError::details()
{
    QTextStream qts;
    qts << "parameters sent :";
    qts << "table = " << table;
    qts << "where = " << where;
    qts << "bindsWhere :";
    for (auto& b : bindsWhere.toStdMap())
        qts << "   {" << b.first << "}, {" << b.second << "}";
    return qts.readAll();
}

Database::QueryTruncateError::QueryTruncateError(QSqlQuery&& query, const QString& table)
    : QueryError(std::move(query))
    , table(table)
{}

QString
Database::QueryTruncateError::details()
{
    QTextStream qts;
    qts << "parameters sent :";
    qts << "table = " << table;
    return qts.readAll();
}

} // namespace lrc
