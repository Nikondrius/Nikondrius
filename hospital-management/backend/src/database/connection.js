import Database from 'better-sqlite3';
import { existsSync } from 'fs';
import { initializeDatabase } from './init.js';

class DatabaseConnection {
    constructor() {
        this.db = null;
        this.dbPath = process.env.DB_PATH || './hospital.db';
    }

    /**
     * Get or create database connection
     * @returns {Database} SQLite database instance
     */
    getConnection() {
        if (!this.db) {
            const dbExists = existsSync(this.dbPath);

            this.db = new Database(this.dbPath);
            this.db.pragma('foreign_keys = ON');
            this.db.pragma('journal_mode = WAL'); // Write-Ahead Logging for better concurrency

            // Initialize database if it's new
            if (!dbExists) {
                console.log('Database does not exist. Initializing...');
                this.db.close();
                this.db = null;
                initializeDatabase(this.dbPath);
                this.db = new Database(this.dbPath);
                this.db.pragma('foreign_keys = ON');
                this.db.pragma('journal_mode = WAL');
            }
        }

        return this.db;
    }

    /**
     * Close database connection
     */
    close() {
        if (this.db) {
            this.db.close();
            this.db = null;
        }
    }

    /**
     * Execute a transaction
     * @param {Function} callback - Function containing database operations
     * @returns {*} Result of the transaction
     */
    transaction(callback) {
        const db = this.getConnection();
        const transaction = db.transaction(callback);
        return transaction();
    }
}

// Singleton instance
const dbConnection = new DatabaseConnection();

export default dbConnection;
