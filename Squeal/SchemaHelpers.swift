import Foundation

/// Escapes a SQL string. For example, escaping `it's it` will produce `'it''s it'`.
public func escapeIdentifier(identifier:String) -> String {
    let escapedString = identifier.stringByReplacingOccurrencesOfString("'",
                                                                        withString: "''",
                                                                        options:    .LiteralSearch,
                                                                        range:      nil)
    
    return "'\(escapedString)\'"
}

// =====================================================================================================================
// MARK:- Schema

/// Describes a database's schema -- its tables, indexes, and other structures. The schema can be accessed through the
/// `schema` property of a Database object.
///
/// Schema objects are immutable, and will not change when the database is updated.
public class SchemaInfo : NSObject {
    
    public convenience override init() {
        self.init(schemaEntries: [SchemaEntryInfo]())
    }
    
    public init(schemaEntries:[SchemaEntryInfo]) {
        self.schemaEntries = schemaEntries
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Schema Items
    
    /// The entries in the Schema, each describing a table, index, or other structure.
    public let schemaEntries: [SchemaEntryInfo]
    
    public subscript(entryName:String) -> SchemaEntryInfo? {
        return entryNamed(entryName)
    }
    
    /// Returns the entry with the given name -- table, index, or trigger.
    public func entryNamed(entryName:String) -> SchemaEntryInfo? {
        for entry in schemaEntries {
            if entry.name == entryName {
                return entry
            }
        }
        return nil
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Tables
    
    /// All database tables.
    public var tables: [SchemaEntryInfo] {
        return schemaEntries.filter { $0.isTable }
    }

    /// The names of all tables in the database.
    public var tableNames: [String] {
        return tables.map { $0.name }
    }
    
    /// Returns the entry for a particular table.
    public func tableNamed(tableName:String) -> SchemaEntryInfo? {
        for entry in schemaEntries {
            if entry.isTable && entry.name == tableName {
                return entry
            }
        }
        return nil
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Indexes
    
    /// All database indexes.
    public var indexes: [SchemaEntryInfo] {
        return schemaEntries.filter { $0.isIndex }
    }
    
    /// The names of all database indexes.
    public var indexNames: [String] {
        return indexes.map { $0.name }
    }
    
    /// :param:   tableName The name of a table
    /// :returns: Descriptions of each index for the given table.
    public func indexesOnTable(tableName: String) -> [SchemaEntryInfo] {
        return schemaEntries.filter { $0.isIndex && $0.tableName == tableName }
    }
    
    /// :param:   tableName The name of a table
    /// :returns: The name of each index on for a table.
    public func namesOfIndexesOnTable(tableName: String) -> [String] {
        return indexesOnTable(tableName).map { $0.name }
    }
    
}

/// Describes a table, index, or other database structure.
///
/// SchemaEntryInfo objects are immutable and will not change when the database is updated.
public class SchemaEntryInfo : NSObject {
    
    public init(type: String?, name: String?, tableName: String?, rootPage: Int?, sql:String?) {
        self.type       = type      ?? ""
        self.name       = name      ?? ""
        self.tableName  = tableName ?? ""
        self.rootPage   = rootPage
        self.sql        = sql
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Type
    
    /// The type of structure represented by this entry.
    public let type: String
    
    /// `type` for tables.
    public let TABLE_TYPE   = "table"
    /// `type` for indexes.
    public let INDEX_TYPE   = "index"
    /// `type` for views.
    public let VIEW_TYPE    = "view"
    /// `type` for triggers.
    public let TRIGGER_TYPE = "trigger"
    
    /// `true` if this entry describes a table, false otherwise.
    public var isTable : Bool {
        return self.type == TABLE_TYPE
    }
    
    /// `true` if this entry describes an index, false otherwise.
    public var isIndex : Bool {
        return self.type == INDEX_TYPE
    }

    /// `true` if this entry describes a view, false otherwise.
    public var isView : Bool {
        return self.type == VIEW_TYPE
    }

    /// `true` if this entry describes a trigger, false otherwise.
    public var isTrigger : Bool {
        return self.type == TRIGGER_TYPE
    }

    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Name
    
    /// The name of the table, index, view, or trigger described by this object.
    public let name: String
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Table Name
    
    /// If this entry describes a table or a view, this is identical to the `name` property. For an index, this is the
    /// name of the table that is indexed by the index. For triggers, this is the name of the table or view that causes
    /// the trigger to fire.
    public let tableName: String
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Root Page
    
    public let rootPage: Int?
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  SQL
    
    /// The SQL string used to create the table, index, view, or trigger. It will be nil for automatically created
    /// objects, like a unique index created in a CREATE TABLE statement (e.g. "emailAddress TEXT UNIQUE NOT NULL")
    public let sql: String?

}

// =====================================================================================================================
// MARK:- Table

/// Describes the structure of a table -- it's columns.
public class TableInfo : NSObject {
    
    public init(name:String, columns:[ColumnInfo], indexes:[IndexInfo]) {
        self.name = name
        self.columns = columns
        self.indexes = indexes
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Name
    
    /// The table name.
    public let name: String
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Columns

    /// Details about the table's columns.
    public let columns: [ColumnInfo]

    /// The names of all columns in the table.
    public var columnNames : [String] {
        return columns.map { $0.name }
    }
    
    public subscript(columnName:String) -> ColumnInfo? {
        for column in columns {
            if column.name == columnName {
                return column
            }
        }
        return nil
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK: Indexes
    
    /// Details about the table's indexes.
    public let indexes: [IndexInfo]

    /// The names of all indexes in the table.
    public var indexNames : [String] {
        return indexes.map { $0.name }
    }
    
    public func indexNamed(name:String) -> IndexInfo? {
        guard let index = indexes.indexOf({ $0.name == name }) else {
            return nil
        }
        
        return indexes[index]
    }
    
}

/// Describes a column in a database table. Derived from the `table_info` PRAGMA.
public class ColumnInfo : NSObject {
    
    public init(index:Int, name:String, type:String?, notNull:Bool, defaultValue:String?, primaryKeyIndex:Int) {
        self.index              = index
        self.name               = name
        self.type               = type
        self.notNull            = notNull
        self.defaultValue       = defaultValue
        self.primaryKeyIndex    = primaryKeyIndex
    }
    
    public init(row:Statement) {
        index           = row.intValue("cid")       ?? 0
        name            = row.stringValue("name")   ?? ""
        type            = row.stringValue("type")
        notNull         = row.boolValue("notnull")  ?? false
        defaultValue    = row.stringValue("dflt_value")
        primaryKeyIndex = row.intValue("pk")        ?? 0
    }
    
    /// The order of the column in the table.
    public let index:           Int

    /// The column's name
    public let name:            String

    /// The type of the column. Since sqlite is dynamically typed, this value is not well defined. But it will often be
    /// 'INTEGER', 'TEXT', 'REAL', or 'BLOB'. However, it can also be missing, or an arbitrary user type.
    public let type:            String?

    /// Whether the column was created with 'NOT NULL'. `true` means the values of the column cannot be nil, `false`
    /// means that NULL is an allowable value.
    public let notNull:         Bool

    /// The default value for the column.
    public let defaultValue:    String?

    /// 0 if the column is not part of the primary key, otherwise the 1-based index within the primary key.
    ///
    /// For example, if a table had a compound key of (name, email_address), then the 'name' column would have a
    /// `primaryKeyIndex` of 1, and the 'email_address' column would be 2.
    public let primaryKeyIndex: Int
    
}

// =====================================================================================================================
// MARK:- Indexes

/// Information about a column within an index. See the `index_list` PRAGMA in sqlite docs.
public class IndexInfo : NSObject {

    /// The name of the index.
    public let name:String
    
    /// A sequence number assigned by sqlite.
    public let sequenceNumber:Int
    
    /// Whether the index is UNIQUE.
    public let isUnique:Bool
    
    /// How the index was created.
    public let origin:IndexOrigin
    
    /// Whether the index is partial.
    public let isPartial:Bool
    
    /// The columns covered by the index.
    public private(set) var columns = [IndexedColumnInfo]()
    
    init(row:Statement) {
        name           = row.stringValueAtIndex(1) ?? ""
        sequenceNumber = row.intValueAtIndex(0) ?? 0
        isUnique       = row.boolValueAtIndex(2) ?? false
        origin         = IndexOrigin(code:row.stringValueAtIndex(3) ?? "")
        isPartial      = row.boolValueAtIndex(4) ?? false
    }
    
    public var columnNames:[String] {
        return columns.map { $0.name ?? "" }
    }
    
}

/// Describes how an index was created. See the `index_list` PRAGMA for details.
public enum IndexOrigin : CustomStringConvertible {
    
    /// A CREATE INDEX statement/
    case CreateIndex
    
    /// A UNIQUE constraint on the table.
    case UniqueConstraint
    
    /// A PRIMARY KEY column constraint.
    case PrimaryKey
    
    /// An unknown origin. `code` is the value returned by sqlite.
    case Other(code:String)
    
    init(code:String) {
        switch code {
        case "c":
            self = CreateIndex
        case "u":
            self = UniqueConstraint
        case "pk":
            self = PrimaryKey
        default:
            self = Other(code:code)
        }
    }
    
    /// Returns the sqlite code for this origin.
    public var description: String {
        switch self {
        case CreateIndex:
            return "c"
        case UniqueConstraint:
            return "u"
        case PrimaryKey:
            return "pk"
        case let Other(code):
            return code
        }
    }
    
}

/// Information about a column within an index. See the `index_xinfo` PRAGMA in sqlite docs.
public class IndexedColumnInfo : NSObject {
    
    let positionInIndex:Int
    let positionInTable:Int?
    let name:String?
    let descending:Bool
    let collatingFunction:String
    let isKey:Bool
    
    init(row:Statement) {
        positionInIndex     = row.intValueAtIndex(0) ?? 0
        positionInTable     = row.intValueAtIndex(1)
        name                = row.stringValueAtIndex(2) ?? ""
        descending          = row.boolValueAtIndex(3) ?? false
        collatingFunction   = row.stringValueAtIndex(4) ?? ""
        isKey               = row.boolValueAtIndex(5) ?? false
    }

}

// =====================================================================================================================
// MARK:- Database

public extension Database {
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  Schema Introspection
    
    /// The database schema. If an error occurs, an empty Schema object is returned.
    public var schema: SchemaInfo {
        var schemaEntries = [SchemaEntryInfo]()
        
        do {
            let statement = try prepareStatement("SELECT * FROM sqlite_master")
            while try statement.next() {
                let schemaEntry = SchemaEntryInfo(type:     statement.stringValue("type"),
                                                  name:     statement.stringValue("name"),
                                                  tableName:statement.stringValue("tbl_name"),
                                                  rootPage: statement.intValue("rootpage"),
                                                  sql:      statement.stringValue("sql"))
                
                schemaEntries.append(schemaEntry)
            }
        } catch let error {
            NSLog("Error preparing statement to read database schema: \(error)")
            return SchemaInfo()
        }
        
        return SchemaInfo(schemaEntries: schemaEntries)
    }
    
    /// Fetches details about a table in the database.
    ///
    /// :param: tableName   A table name
    /// :param: error       An error pointer
    /// :returns: A TableInfo object describing the table and its columns. `nil` if table doesn't exist
    ///
    public func tableInfoForTableNamed(tableName:String) throws -> TableInfo? {
        var columns = [ColumnInfo]()
        
        let columnInfoRow = try prepareStatement("PRAGMA table_info(" + escapeIdentifier(tableName) + ")")
        while try columnInfoRow.next() {
            let columnInfo = ColumnInfo(row:columnInfoRow)
            
            columns.append(columnInfo)
        }
        
        guard !columns.isEmpty else {
            return nil
        }
        
        var indexes = [IndexInfo]()
        let indexInfoRow = try prepareStatement("PRAGMA index_list(" + escapeIdentifier(tableName) + ")")
        while try indexInfoRow.next() {
            let info = IndexInfo(row:indexInfoRow)
            indexes.append(info)
        }
        
        for index in indexes {
            let indexColumnInfoRow = try prepareStatement("PRAGMA index_info(" + escapeIdentifier(index.name) + ")")
            while try indexColumnInfoRow.next() {
                index.columns.append(IndexedColumnInfo(row:indexColumnInfoRow))
            }
        }
        
        return TableInfo(name: tableName, columns: columns, indexes:indexes)
    }
    
    /// Fetches the 'user_version' value, a user-defined version number for the database. This is useful for managing
    /// migrations.
    ///
    public func queryUserVersionNumber() throws -> Int32 {
        let userViewSql = "PRAGMA user_version"
        let statement = try prepareStatement(userViewSql)

        var userVersionNumber:Int32 = 0
        if try statement.next() {
            userVersionNumber = Int32(statement.intValueAtIndex(0) ?? 0)
        }
        return userVersionNumber
    }

    /// Sets the 'user_version' value, a user-defined version number for the database. This is useful for managing
    /// migrations.
    ///
    /// :param: number      The version number to set
    ///
    public func updateUserVersionNumber(number:Int32) throws {
        return try execute("PRAGMA user_version=\(number)")
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  CREATE TABLE
    
    /// Creates a table. This is a helper for executing a CREATE TABLE statement.
    ///
    /// :param: tableName   The name of the table.
    /// :param: definitions Column and constraint definitions. For example, "name TEXT NOT NULL".
    /// :param: ifNotExists If `true`, don't create the table if it already exists. If `false`, then this method will
    ///                     return an error if the table exists already. Defaults to false.
    ///
    public func createTable(tableName:String,
                            definitions:[String],
                            ifNotExists:Bool = false) throws {
        var createTableSql = [ "CREATE TABLE" ]
        if ifNotExists {
            createTableSql.append("IF NOT EXISTS")
        }
        createTableSql.append(escapeIdentifier(tableName))
        createTableSql.append("(")
        createTableSql.append(definitions.joinWithSeparator(","))
        createTableSql.append(")")
                                
        return try execute(createTableSql.joinWithSeparator(" "))
    }

    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  DROP TABLE
    
    /// Removes a table. This is a helper for executing a DROP TABLE statement.
    ///
    /// :param: tableName   The name of the table.
    /// :param: ifExists    If `true`, only drop the table if it exists. If `false`, then this method will return an
    ///                     error if the table doesn't exist. Defaults to false.
    ///
    public func dropTable(tableName:String, ifExists:Bool = false) throws {
        var dropTableSql = "DROP TABLE "
        if ifExists {
            dropTableSql += "IF EXISTS "
        }
        dropTableSql += escapeIdentifier(tableName)
        
        return try execute(dropTableSql)
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  ALTER TABLE
    
    /// Renames a table. This is a helper for executing a ALTER TABLE ... RENAME TO statement.
    ///
    /// :param: tableName   The current name of the table.
    /// :param: to          The new name of the table.
    ///
    public func renameTable(tableName:String, to:String) throws {
        let renameTableSql = "ALTER TABLE " + escapeIdentifier(tableName)
                                + " RENAME TO " + escapeIdentifier(to)
        
        return try execute(renameTableSql)
    }
    
    /// Adds a column to a table. This is a helper for executing a ALTER TABLE ... ADD COLUMN statement.
    ///
    /// :param: tableName   The name of the table.
    /// :param: column      The column definition, such as "name TEXT NOT NULL DEFAULT ''"
    ///
    public func addColumnToTable(tableName:String, column:String) throws {
        let addColumnSql = "ALTER TABLE " + escapeIdentifier(tableName)
                                + " ADD COLUMN " + column
        
        return try execute(addColumnSql)
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  CREATE INDEX
    
    /// Creates a table index. This is a helper for executing a CREATE INDEX statement.
    ///
    /// :param: name        The name of the index.
    /// :param: tableName   The name of the table to index.
    /// :param: columns     The columns to index.
    /// :param: unique      Whether to create a unique index of not. Defaults to false.
    /// :param: ifNotExists If `true`, don't create the index if it already exists. If `false`, then this method will
    ///                     return an error if the index already exists. Defaults to false.
    /// :param: partialExpr An expression to create a partial index.
    ///
    public func createIndex(name:String,
                            tableName:String,
                            columns:[String],
                            partialExpr:String? = nil,
                            unique:Bool = false,
                            ifNotExists:Bool = false) throws {
                                
        var createIndexSql = [ "CREATE" ]
        if unique {
            createIndexSql.append("UNIQUE")
        }
        createIndexSql.append("INDEX")
        if ifNotExists {
            createIndexSql.append("IF NOT EXISTS")
        }
        
        createIndexSql.append(escapeIdentifier(name))
        createIndexSql.append("ON")
        createIndexSql.append(escapeIdentifier(tableName))
        createIndexSql.append("(")
        createIndexSql.append(columns.joinWithSeparator(", "))
        createIndexSql.append(")")
        
        if let partialExpr = partialExpr {
            createIndexSql.append("WHERE")
            createIndexSql.append(partialExpr)
        }
        
        return try execute(createIndexSql.joinWithSeparator(" "))
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // MARK:  DROP INDEX
    
    /// Removes a table index. This is a helper for executing a DROP INDEX statement.
    ///
    /// :param: name        The name of the index.
    /// :param: ifExists    If `true`, only remove the index if it exists. If `false`, then this method will return an
    ///                     error if the index doesn't exist. Defaults to false.
    ///
    public func dropIndex(indexName:String, ifExists:Bool = false) throws {
        var dropIndexSql = "DROP INDEX "
        if ifExists {
            dropIndexSql += "IF EXISTS "
        }
        dropIndexSql += escapeIdentifier(indexName)
        
        return try execute(dropIndexSql)
    }
}
