import Foundation
import GRDB

enum AppDatabaseMigrations {
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        #if DEBUG
        // Wipe database when schema changes during development.
        // Remove this before shipping to production.
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        // MARK: - v1: Initial Schema

        migrator.registerMigration("v1_createUsers") { db in
            try db.create(table: "users") { t in
                t.primaryKey("id", .text).notNull()
                t.column("name", .text).notNull()
                t.column("email", .text).notNull()
                t.column("provider", .text).notNull()
                t.column("subscriptionTier", .text).notNull().defaults(to: "free")
                t.column("scanQuotaUsed", .integer).notNull().defaults(to: 0)
                t.column("aiQuotaUsed", .integer).notNull().defaults(to: 0)
                t.column("onboardingCompleted", .boolean).notNull().defaults(to: false)
            }
        }

        migrator.registerMigration("v1_createWorkouts") { db in
            try db.create(table: "workouts") { t in
                t.primaryKey("id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("content", .text)
                t.column("source", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }

        migrator.registerMigration("v1_createBodyMetrics") { db in
            try db.create(table: "bodyMetrics") { t in
                t.primaryKey("id", .text).notNull()
                t.column("weight", .double).notNull()
                t.column("date", .date).notNull()
                t.column("notes", .text)
            }
        }

        migrator.registerMigration("v1_createSyncQueue") { db in
            try db.create(table: "syncQueue") { t in
                t.primaryKey("id", .text).notNull()
                t.column("entity", .text).notNull()
                t.column("operation", .text).notNull()
                t.column("entityId", .text).notNull()
                t.column("payload", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("retryCount", .integer).notNull().defaults(to: 0)
                t.column("lastError", .text)
                t.column("nextAttemptAt", .datetime)
            }
        }

        return migrator
    }
}
