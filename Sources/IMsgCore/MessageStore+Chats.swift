import Foundation
import SQLite

extension MessageStore {
  public func listChats(limit: Int) throws -> [Chat] {
    let accountIDColumn = hasChatAccountIDColumn ? "IFNULL(c.account_id, '')" : "''"
    let accountLoginColumn = hasChatAccountLoginColumn ? "IFNULL(c.account_login, '')" : "''"
    let lastAddressedHandleColumn =
      hasChatLastAddressedHandleColumn ? "IFNULL(c.last_addressed_handle, '')" : "''"
    let sql: String
    if hasChatMessageJoinMessageDateColumn {
      sql = """
        SELECT c.ROWID, IFNULL(c.display_name, c.chat_identifier) AS name, c.chat_identifier,
               c.service_name, MAX(cmj.message_date) AS last_date,
               \(accountIDColumn) AS account_id,
               \(accountLoginColumn) AS account_login,
               \(lastAddressedHandleColumn) AS last_addressed_handle
        FROM chat c
        JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
        GROUP BY c.ROWID
        ORDER BY last_date DESC
        LIMIT ?
        """
    } else {
      sql = """
        SELECT c.ROWID, IFNULL(c.display_name, c.chat_identifier) AS name, c.chat_identifier,
               c.service_name, MAX(m.date) AS last_date,
               \(accountIDColumn) AS account_id,
               \(accountLoginColumn) AS account_login,
               \(lastAddressedHandleColumn) AS last_addressed_handle
        FROM chat c
        JOIN chat_message_join cmj ON c.ROWID = cmj.chat_id
        JOIN message m ON m.ROWID = cmj.message_id
        GROUP BY c.ROWID
        ORDER BY last_date DESC
        LIMIT ?
        """
    }
    return try withConnection { db in
      var chats: [Chat] = []
      for row in try db.prepare(sql, limit) {
        chats.append(
          Chat(
            id: int64Value(row[0]) ?? 0,
            identifier: stringValue(row[2]),
            name: stringValue(row[1]),
            service: stringValue(row[3]),
            lastMessageAt: appleDate(from: int64Value(row[4])),
            accountID: stringValue(row[5]).nilIfEmpty,
            accountLogin: stringValue(row[6]).nilIfEmpty,
            lastAddressedHandle: stringValue(row[7]).nilIfEmpty
          ))
      }
      return chats
    }
  }

  public func chatInfo(chatID: Int64) throws -> ChatInfo? {
    let accountIDColumn = hasChatAccountIDColumn ? "IFNULL(c.account_id, '')" : "''"
    let accountLoginColumn = hasChatAccountLoginColumn ? "IFNULL(c.account_login, '')" : "''"
    let lastAddressedHandleColumn =
      hasChatLastAddressedHandleColumn ? "IFNULL(c.last_addressed_handle, '')" : "''"
    let sql = """
      SELECT c.ROWID, IFNULL(c.chat_identifier, '') AS identifier, IFNULL(c.guid, '') AS guid,
             IFNULL(c.display_name, c.chat_identifier) AS name, IFNULL(c.service_name, '') AS service,
             \(accountIDColumn) AS account_id,
             \(accountLoginColumn) AS account_login,
             \(lastAddressedHandleColumn) AS last_addressed_handle
      FROM chat c
      WHERE c.ROWID = ?
      LIMIT 1
      """
    return try withConnection { db in
      for row in try db.prepare(sql, chatID) {
        return ChatInfo(
          id: int64Value(row[0]) ?? 0,
          identifier: stringValue(row[1]),
          guid: stringValue(row[2]),
          name: stringValue(row[3]),
          service: stringValue(row[4]),
          accountID: stringValue(row[5]).nilIfEmpty,
          accountLogin: stringValue(row[6]).nilIfEmpty,
          lastAddressedHandle: stringValue(row[7]).nilIfEmpty
        )
      }
      return nil
    }
  }

  public func participants(chatID: Int64) throws -> [String] {
    let sql = """
      SELECT h.id
      FROM chat_handle_join chj
      JOIN handle h ON h.ROWID = chj.handle_id
      WHERE chj.chat_id = ?
      ORDER BY h.id ASC
      """
    return try withConnection { db in
      var results: [String] = []
      var seen = Set<String>()
      for row in try db.prepare(sql, chatID) {
        let handle = stringValue(row[0])
        if handle.isEmpty { continue }
        if seen.insert(handle).inserted {
          results.append(handle)
        }
      }
      return results
    }
  }
}
