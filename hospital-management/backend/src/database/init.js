import Database from 'better-sqlite3';
import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Initialize the hospital management database
 * Creates tables, indexes, triggers, and seeds initial data
 */
export function initializeDatabase(dbPath = './hospital.db') {
    try {
        console.log('Initializing hospital management database...');

        const db = new Database(dbPath, { verbose: console.log });

        // Enable foreign keys
        db.pragma('foreign_keys = ON');

        // Read and execute schema
        const schemaPath = join(__dirname, 'schema.sql');
        const schema = readFileSync(schemaPath, 'utf-8');

        // Execute entire schema at once (handles triggers and complex statements better)
        db.exec(schema);

        console.log('Database initialized successfully!');
        console.log(`Location: ${dbPath}`);

        // Display initial stats
        const deptCount = db.prepare('SELECT COUNT(*) as count FROM departments').get();
        console.log(`\nSeeded ${deptCount.count} departments`);

        db.close();
        return true;
    } catch (error) {
        console.error('Failed to initialize database:', error);
        return false;
    }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    initializeDatabase();
}

export default initializeDatabase;
