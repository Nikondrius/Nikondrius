import express from 'express';
import cors from 'cors';
import patientService from './services/patientService.js';
import bedAllocationService from './services/bedAllocation.js';
import dbConnection from './database/connection.js';

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Error handling middleware
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

// ==================== HEALTH CHECK ====================

app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'Hospital Management System API'
    });
});

// ==================== PATIENT ENDPOINTS ====================

/**
 * Register a new patient
 * POST /api/patients
 */
app.post('/api/patients', asyncHandler(async (req, res) => {
    const result = patientService.registerPatient(req.body);
    res.status(201).json(result);
}));

/**
 * Search patients
 * GET /api/patients/search?q=searchTerm
 */
app.get('/api/patients/search', asyncHandler(async (req, res) => {
    const searchTerm = req.query.q || '';
    const patients = patientService.searchPatients(searchTerm);
    res.json(patients);
}));

/**
 * Get patient details
 * GET /api/patients/:id
 */
app.get('/api/patients/:id', asyncHandler(async (req, res) => {
    const patient = patientService.getPatient(parseInt(req.params.id));
    res.json(patient);
}));

/**
 * Update patient information
 * PUT /api/patients/:id
 */
app.put('/api/patients/:id', asyncHandler(async (req, res) => {
    const result = patientService.updatePatient(parseInt(req.params.id), req.body);
    res.json(result);
}));

/**
 * Get patient admission history
 * GET /api/patients/:id/admissions
 */
app.get('/api/patients/:id/admissions', asyncHandler(async (req, res) => {
    const history = patientService.getAdmissionHistory(parseInt(req.params.id));
    res.json(history);
}));

// ==================== ADMISSION ENDPOINTS ====================

/**
 * Admit a patient
 * POST /api/admissions
 */
app.post('/api/admissions', asyncHandler(async (req, res) => {
    const result = patientService.admitPatient(req.body);
    res.status(201).json(result);
}));

/**
 * Get all active admissions
 * GET /api/admissions/active
 */
app.get('/api/admissions/active', asyncHandler(async (req, res) => {
    const admissions = patientService.getActiveAdmissions();
    res.json(admissions);
}));

/**
 * Discharge a patient
 * POST /api/admissions/:id/discharge
 */
app.post('/api/admissions/:id/discharge', asyncHandler(async (req, res) => {
    const result = bedAllocationService.dischargePatient(
        parseInt(req.params.id),
        req.body.notes || ''
    );
    res.json(result);
}));

// ==================== BED MANAGEMENT ENDPOINTS ====================

/**
 * Get bed availability across all departments
 * GET /api/beds/availability
 */
app.get('/api/beds/availability', asyncHandler(async (req, res) => {
    const availability = bedAllocationService.getBedAvailability();
    res.json(availability);
}));

/**
 * Get detailed bed status for a department
 * GET /api/beds/department/:departmentId
 */
app.get('/api/beds/department/:departmentId', asyncHandler(async (req, res) => {
    const beds = bedAllocationService.getDepartmentBedStatus(parseInt(req.params.departmentId));
    res.json(beds);
}));

// ==================== DEPARTMENT ENDPOINTS ====================

/**
 * Get all departments
 * GET /api/departments
 */
app.get('/api/departments', asyncHandler(async (req, res) => {
    const db = dbConnection.getConnection();
    const departments = db.prepare(`
        SELECT
            id,
            name,
            department_type,
            total_beds,
            available_beds,
            ROUND(CAST(available_beds AS FLOAT) / total_beds * 100, 1) as availability_percentage
        FROM departments
        ORDER BY name
    `).all();
    res.json(departments);
}));

/**
 * Get department details
 * GET /api/departments/:id
 */
app.get('/api/departments/:id', asyncHandler(async (req, res) => {
    const db = dbConnection.getConnection();
    const department = db.prepare(`
        SELECT * FROM departments WHERE id = ?
    `).get(parseInt(req.params.id));

    if (!department) {
        return res.status(404).json({ error: 'Department not found' });
    }

    res.json(department);
}));

// ==================== STAFF ENDPOINTS ====================

/**
 * Get all staff
 * GET /api/staff
 */
app.get('/api/staff', asyncHandler(async (req, res) => {
    const db = dbConnection.getConnection();
    const role = req.query.role; // Optional filter by role

    let query = `
        SELECT
            s.id,
            s.staff_number,
            s.first_name || ' ' || s.last_name as full_name,
            s.role,
            s.specialization,
            s.status,
            d.name as department_name
        FROM staff s
        LEFT JOIN departments d ON s.department_id = d.id
        WHERE s.status = 'ACTIVE'
    `;

    if (role) {
        query += ` AND s.role = ?`;
        const staff = db.prepare(query).all(role);
        return res.json(staff);
    }

    const staff = db.prepare(query).all();
    res.json(staff);
}));

/**
 * Register new staff member
 * POST /api/staff
 */
app.post('/api/staff', asyncHandler(async (req, res) => {
    const db = dbConnection.getConnection();

    // Generate staff number
    const staffNumber = `S-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const result = db.prepare(`
        INSERT INTO staff (
            staff_number, first_name, last_name, role,
            specialization, department_id, phone, email, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')
    `).run(
        staffNumber,
        req.body.first_name,
        req.body.last_name,
        req.body.role,
        req.body.specialization,
        req.body.department_id,
        req.body.phone,
        req.body.email
    );

    res.status(201).json({
        success: true,
        staff_id: result.lastInsertRowid,
        staff_number: staffNumber,
        message: 'Staff member registered successfully'
    });
}));

// ==================== DASHBOARD STATS ENDPOINT ====================

/**
 * Get dashboard statistics
 * GET /api/dashboard/stats
 */
app.get('/api/dashboard/stats', asyncHandler(async (req, res) => {
    const db = dbConnection.getConnection();

    const stats = {
        total_patients: db.prepare('SELECT COUNT(*) as count FROM patients').get().count,
        active_admissions: db.prepare('SELECT COUNT(*) as count FROM admissions WHERE status IN ("WAITING", "ADMITTED")').get().count,
        available_beds: db.prepare('SELECT SUM(available_beds) as count FROM departments').get().count,
        total_beds: db.prepare('SELECT SUM(total_beds) as count FROM departments').get().count,
        emergency_cases: db.prepare('SELECT COUNT(*) as count FROM admissions WHERE admission_type = "EMERGENCY" AND status IN ("WAITING", "ADMITTED")').get().count,
        waiting_queue: db.prepare('SELECT COUNT(*) as count FROM admissions WHERE status = "WAITING"').get().count,
        occupancy_rate: 0
    };

    if (stats.total_beds > 0) {
        stats.occupancy_rate = Math.round(((stats.total_beds - stats.available_beds) / stats.total_beds) * 100);
    }

    // Recent admissions (last 24 hours)
    stats.recent_admissions = db.prepare(`
        SELECT COUNT(*) as count
        FROM admissions
        WHERE admission_date >= datetime('now', '-1 day')
    `).get().count;

    res.json(stats);
}));

// ==================== ERROR HANDLING ====================

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: `Route ${req.method} ${req.path} not found`
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);

    res.status(err.status || 500).json({
        error: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// ==================== SERVER START ====================

const server = app.listen(PORT, () => {
    console.log('\n=================================');
    console.log('Hospital Management System API');
    console.log('=================================');
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Database: ${dbConnection.dbPath}`);
    console.log('\nAvailable endpoints:');
    console.log('  GET  /api/health');
    console.log('  GET  /api/dashboard/stats');
    console.log('  GET  /api/beds/availability');
    console.log('  GET  /api/patients/search?q=...');
    console.log('  POST /api/patients');
    console.log('  POST /api/admissions');
    console.log('  GET  /api/admissions/active');
    console.log('  GET  /api/departments');
    console.log('  GET  /api/staff');
    console.log('=================================\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    server.close(() => {
        dbConnection.close();
        console.log('Server closed');
        process.exit(0);
    });
});

export default app;
