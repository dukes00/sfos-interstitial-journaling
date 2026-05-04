#ifndef JOURNALSTORE_H
#define JOURNALSTORE_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QVector>

struct JournalEntry {
    QDateTime timestamp;
    QString text;
};

class JournalStore : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        TimestampRole = Qt::UserRole + 1,
        TextRole,
        TimeDisplayRole,
        DateDisplayRole,
        IsNewDayRole
    };

    explicit JournalStore(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    Q_INVOKABLE void loadEntries(int limit = 100);
    Q_INVOKABLE void appendEntry(const QString &text);
    Q_INVOKABLE QString randomPrompt() const;

signals:
    void countChanged();

private:
    QString journalPath() const;
    bool ensureDir() const;

    QVector<JournalEntry> m_entries;
};

#endif // JOURNALSTORE_H
