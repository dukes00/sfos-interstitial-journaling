#include "journalstore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTextStream>
#include <QUuid>

static const QStringList PROMPTS = {
    QStringLiteral("what are you doing right now?"),
    QStringLiteral("what's happening?"),
    QStringLiteral("what just happened?"),
    QStringLiteral("what's on your mind?"),
    QStringLiteral("what are you working on?"),
    QStringLiteral("capture this moment"),
};

JournalStore::JournalStore(QObject *parent)
    : QAbstractListModel(parent)
{
}

int JournalStore::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_entries.size();
}

QVariant JournalStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_entries.size())
        return QVariant();

    const JournalEntry &entry = m_entries.at(index.row());

    switch (role) {
    case TimestampRole:
        return entry.timestamp;
    case TextRole:
        return entry.text;
    case TimeDisplayRole:
        return entry.timestamp.toString(QStringLiteral("HH:mm"));
    case DateDisplayRole:
        return entry.timestamp.toString(QStringLiteral("yyyy-MM-dd"));
    case IsNewDayRole: {
        if (index.row() == 0)
            return true;
        const JournalEntry &prev = m_entries.at(index.row() - 1);
        return entry.timestamp.date() != prev.timestamp.date();
    }
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> JournalStore::roleNames() const
{
    return {
        { TimestampRole, "timestamp" },
        { TextRole, "entryText" },
        { TimeDisplayRole, "timeDisplay" },
        { DateDisplayRole, "dateDisplay" },
        { IsNewDayRole, "isNewDay" }
    };
}

int JournalStore::count() const
{
    return m_entries.size();
}

QString JournalStore::journalPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/journal.txt");
}

bool JournalStore::ensureDir() const
{
    QFileInfo fi(journalPath());
    return QDir().mkpath(fi.absolutePath());
}

void JournalStore::loadEntries(int limit)
{
    beginResetModel();
    m_entries.clear();

    QFile file(journalPath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        endResetModel();
        return;
    }

    // Read all lines, keep last `limit`
    QVector<JournalEntry> allEntries;
    QTextStream in(&file);
    while (!in.atEnd()) {
        const QString line = in.readLine().trimmed();
        if (line.isEmpty())
            continue;

        // Format: ISO8601<space>text
        const int spaceIdx = line.indexOf(' ');
        if (spaceIdx < 0)
            continue;

        const QString tsStr = line.left(spaceIdx);
        const QString text = line.mid(spaceIdx + 1);
        const QDateTime ts = QDateTime::fromString(tsStr, Qt::ISODate);
        if (!ts.isValid())
            continue;

        allEntries.append({ ts, text });
    }
    file.close();

    // Keep last N entries
    const int start = qMax(0, allEntries.size() - limit);
    for (int i = start; i < allEntries.size(); ++i)
        m_entries.append(allEntries.at(i));

    endResetModel();
    emit countChanged();
}

void JournalStore::appendEntry(const QString &text)
{
    if (text.trimmed().isEmpty())
        return;

    if (!ensureDir())
        return;

    const QDateTime now = QDateTime::currentDateTimeUtc().toLocalTime();
    const QString line = now.toString(Qt::ISODate) + ' ' + text.trimmed() + '\n';

    // Write to file
    QFile file(journalPath());
    if (!file.open(QIODevice::Append | QIODevice::Text))
        return;
    QTextStream out(&file);
    out << line;
    file.close();

    // Add to model
    const int row = m_entries.size();
    beginInsertRows(QModelIndex(), row, row);
    m_entries.append({ now, text.trimmed() });
    endInsertRows();
    emit countChanged();
}

QString JournalStore::randomPrompt() const
{
    return PROMPTS.at(qrand() % PROMPTS.size());
}
