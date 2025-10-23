-- Hospital Management System Database Schema
-- Designed for production use with proper constraints and indexes

-- Departments Table
CREATE TABLE IF NOT EXISTS departments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    total_beds INTEGER NOT NULL CHECK(total_beds > 0),
    available_beds INTEGER NOT NULL CHECK(available_beds >= 0),
    department_type TEXT NOT NULL CHECK(department_type IN ('ICU', 'EMERGENCY', 'GENERAL', 'SURGERY', 'PEDIATRICS', 'MATERNITY')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Beds Table
CREATE TABLE IF NOT EXISTS beds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    bed_number TEXT NOT NULL UNIQUE,
    department_id INTEGER NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED')) DEFAULT 'AVAILABLE',
    bed_type TEXT NOT NULL CHECK(bed_type IN ('STANDARD', 'ICU', 'ISOLATION', 'VENTILATOR')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE
);

-- Patients Table
CREATE TABLE IF NOT EXISTS patients (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_number TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    date_of_birth DATE NOT NULL,
    gender TEXT CHECK(gender IN ('M', 'F', 'OTHER')),
    blood_type TEXT CHECK(blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    phone TEXT,
    email TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    medical_history TEXT,
    allergies TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Admissions Table
CREATE TABLE IF NOT EXISTS admissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL,
    bed_id INTEGER,
    department_id INTEGER NOT NULL,
    admission_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    discharge_date DATETIME,
    admission_type TEXT NOT NULL CHECK(admission_type IN ('EMERGENCY', 'SCHEDULED', 'TRANSFER')),
    priority_level INTEGER NOT NULL CHECK(priority_level BETWEEN 1 AND 5) DEFAULT 3,
    diagnosis TEXT,
    treatment_plan TEXT,
    status TEXT NOT NULL CHECK(status IN ('WAITING', 'ADMITTED', 'DISCHARGED', 'TRANSFERRED')) DEFAULT 'WAITING',
    assigned_doctor_id INTEGER,
    assigned_nurse_id INTEGER,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (bed_id) REFERENCES beds(id) ON DELETE SET NULL,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE RESTRICT,
    FOREIGN KEY (assigned_doctor_id) REFERENCES staff(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_nurse_id) REFERENCES staff(id) ON DELETE SET NULL
);

-- Staff Table
CREATE TABLE IF NOT EXISTS staff (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    staff_number TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('DOCTOR', 'NURSE', 'ADMIN', 'TECHNICIAN')),
    specialization TEXT,
    department_id INTEGER,
    phone TEXT,
    email TEXT UNIQUE,
    status TEXT NOT NULL CHECK(status IN ('ACTIVE', 'ON_LEAVE', 'INACTIVE')) DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL
);

-- Audit Log for tracking critical operations
CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    record_id INTEGER NOT NULL,
    operation TEXT NOT NULL CHECK(operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values TEXT,
    new_values TEXT,
    changed_by TEXT,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_beds_department ON beds(department_id);
CREATE INDEX IF NOT EXISTS idx_beds_status ON beds(status);
CREATE INDEX IF NOT EXISTS idx_patients_number ON patients(patient_number);
CREATE INDEX IF NOT EXISTS idx_admissions_patient ON admissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_admissions_status ON admissions(status);
CREATE INDEX IF NOT EXISTS idx_admissions_date ON admissions(admission_date);
CREATE INDEX IF NOT EXISTS idx_staff_department ON staff(department_id);
CREATE INDEX IF NOT EXISTS idx_staff_role ON staff(role);

-- Triggers to maintain data integrity
CREATE TRIGGER IF NOT EXISTS update_department_timestamp
AFTER UPDATE ON departments
BEGIN
    UPDATE departments SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_bed_timestamp
AFTER UPDATE ON beds
BEGIN
    UPDATE beds SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_patient_timestamp
AFTER UPDATE ON patients
BEGIN
    UPDATE patients SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_admission_timestamp
AFTER UPDATE ON admissions
BEGIN
    UPDATE admissions SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

-- Seed initial data for testing
INSERT OR IGNORE INTO departments (id, name, total_beds, available_beds, department_type) VALUES
    (1, 'Emergency Department', 20, 20, 'EMERGENCY'),
    (2, 'Intensive Care Unit', 15, 15, 'ICU'),
    (3, 'General Ward', 50, 50, 'GENERAL'),
    (4, 'Surgical Ward', 25, 25, 'SURGERY'),
    (5, 'Pediatrics', 30, 30, 'PEDIATRICS'),
    (6, 'Maternity Ward', 20, 20, 'MATERNITY');

-- Seed beds for each department
-- Emergency Department (20 beds)
INSERT OR IGNORE INTO beds (bed_number, department_id, status, bed_type) VALUES
    ('ED-001', 1, 'AVAILABLE', 'STANDARD'), ('ED-002', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-003', 1, 'AVAILABLE', 'STANDARD'), ('ED-004', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-005', 1, 'AVAILABLE', 'STANDARD'), ('ED-006', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-007', 1, 'AVAILABLE', 'STANDARD'), ('ED-008', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-009', 1, 'AVAILABLE', 'STANDARD'), ('ED-010', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-011', 1, 'AVAILABLE', 'ICU'), ('ED-012', 1, 'AVAILABLE', 'ICU'),
    ('ED-013', 1, 'AVAILABLE', 'ICU'), ('ED-014', 1, 'AVAILABLE', 'ICU'),
    ('ED-015', 1, 'AVAILABLE', 'ICU'), ('ED-016', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-017', 1, 'AVAILABLE', 'STANDARD'), ('ED-018', 1, 'AVAILABLE', 'STANDARD'),
    ('ED-019', 1, 'AVAILABLE', 'STANDARD'), ('ED-020', 1, 'AVAILABLE', 'STANDARD');

-- ICU (15 beds)
INSERT OR IGNORE INTO beds (bed_number, department_id, status, bed_type) VALUES
    ('ICU-001', 2, 'AVAILABLE', 'ICU'), ('ICU-002', 2, 'AVAILABLE', 'ICU'),
    ('ICU-003', 2, 'AVAILABLE', 'ICU'), ('ICU-004', 2, 'AVAILABLE', 'ICU'),
    ('ICU-005', 2, 'AVAILABLE', 'ICU'), ('ICU-006', 2, 'AVAILABLE', 'ICU'),
    ('ICU-007', 2, 'AVAILABLE', 'ICU'), ('ICU-008', 2, 'AVAILABLE', 'ICU'),
    ('ICU-009', 2, 'AVAILABLE', 'ICU'), ('ICU-010', 2, 'AVAILABLE', 'ICU'),
    ('ICU-011', 2, 'AVAILABLE', 'VENTILATOR'), ('ICU-012', 2, 'AVAILABLE', 'VENTILATOR'),
    ('ICU-013', 2, 'AVAILABLE', 'VENTILATOR'), ('ICU-014', 2, 'AVAILABLE', 'ICU'),
    ('ICU-015', 2, 'AVAILABLE', 'ICU');

-- General Ward (50 beds)
INSERT OR IGNORE INTO beds (bed_number, department_id, status, bed_type)
SELECT 'GEN-' || printf('%03d', value), 3, 'AVAILABLE', 'STANDARD'
FROM (WITH RECURSIVE cnt(value) AS (SELECT 1 UNION ALL SELECT value+1 FROM cnt WHERE value < 50) SELECT value FROM cnt);

-- Surgical Ward (25 beds)
INSERT OR IGNORE INTO beds (bed_number, department_id, status, bed_type)
SELECT 'SUR-' || printf('%03d', value), 4, 'AVAILABLE', 'STANDARD'
FROM (WITH RECURSIVE cnt(value) AS (SELECT 1 UNION ALL SELECT value+1 FROM cnt WHERE value < 25) SELECT value FROM cnt);

-- Pediatrics (30 beds)
INSERT OR IGNORE INTO beds (bed_number, department_id, status, bed_type)
SELECT 'PED-' || printf('%03d', value), 5, 'AVAILABLE', 'STANDARD'
FROM (WITH RECURSIVE cnt(value) AS (SELECT 1 UNION ALL SELECT value+1 FROM cnt WHERE value < 30) SELECT value FROM cnt);

-- Maternity Ward (20 beds)
INSERT OR IGNORE INTO beds (bed_number, department_id, status, bed_type)
SELECT 'MAT-' || printf('%03d', value), 6, 'AVAILABLE', 'STANDARD'
FROM (WITH RECURSIVE cnt(value) AS (SELECT 1 UNION ALL SELECT value+1 FROM cnt WHERE value < 20) SELECT value FROM cnt);
