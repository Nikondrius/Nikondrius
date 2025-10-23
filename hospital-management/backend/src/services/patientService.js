import dbConnection from '../database/connection.js';
import bedAllocationService from './bedAllocation.js';

/**
 * Patient Service
 * Manages patient records and admission workflows
 */
class PatientService {
    /**
     * Register a new patient
     */
    registerPatient(patientData) {
        const db = dbConnection.getConnection();

        try {
            // Generate unique patient number
            const patientNumber = this.generatePatientNumber();

            const result = db.prepare(`
                INSERT INTO patients (
                    patient_number, first_name, last_name, date_of_birth,
                    gender, blood_type, phone, email,
                    emergency_contact_name, emergency_contact_phone,
                    medical_history, allergies
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `).run(
                patientNumber,
                patientData.first_name,
                patientData.last_name,
                patientData.date_of_birth,
                patientData.gender,
                patientData.blood_type,
                patientData.phone,
                patientData.email,
                patientData.emergency_contact_name,
                patientData.emergency_contact_phone,
                patientData.medical_history,
                patientData.allergies
            );

            return {
                success: true,
                patient_id: result.lastInsertRowid,
                patient_number: patientNumber,
                message: 'Patient registered successfully'
            };
        } catch (error) {
            console.error('Patient registration error:', error);
            throw error;
        }
    }

    /**
     * Generate unique patient number (format: P-YYYYMMDD-####)
     */
    generatePatientNumber() {
        const db = dbConnection.getConnection();
        const date = new Date().toISOString().split('T')[0].replace(/-/g, '');

        const lastPatient = db.prepare(`
            SELECT patient_number
            FROM patients
            WHERE patient_number LIKE ?
            ORDER BY id DESC
            LIMIT 1
        `).get(`P-${date}-%`);

        let sequence = 1;
        if (lastPatient) {
            const lastSeq = parseInt(lastPatient.patient_number.split('-')[2]);
            sequence = lastSeq + 1;
        }

        return `P-${date}-${sequence.toString().padStart(4, '0')}`;
    }

    /**
     * Admit a patient to the hospital
     */
    admitPatient(admissionData) {
        const db = dbConnection.getConnection();

        try {
            // Validate patient exists
            const patient = db.prepare('SELECT id FROM patients WHERE id = ?').get(admissionData.patient_id);

            if (!patient) {
                throw new Error('Patient not found');
            }

            // Check for active admissions
            const activeAdmission = db.prepare(`
                SELECT id FROM admissions
                WHERE patient_id = ? AND status IN ('WAITING', 'ADMITTED')
            `).get(admissionData.patient_id);

            if (activeAdmission) {
                throw new Error('Patient already has an active admission');
            }

            // Use bed allocation service
            const allocationResult = bedAllocationService.allocateBed(admissionData);

            return allocationResult;
        } catch (error) {
            console.error('Patient admission error:', error);
            throw error;
        }
    }

    /**
     * Get patient details
     */
    getPatient(patientId) {
        const db = dbConnection.getConnection();

        const patient = db.prepare(`
            SELECT
                p.*,
                (SELECT COUNT(*) FROM admissions WHERE patient_id = p.id) as total_admissions
            FROM patients p
            WHERE p.id = ?
        `).get(patientId);

        if (!patient) {
            throw new Error('Patient not found');
        }

        return patient;
    }

    /**
     * Search patients by various criteria
     */
    searchPatients(searchTerm) {
        const db = dbConnection.getConnection();

        const patients = db.prepare(`
            SELECT
                id,
                patient_number,
                first_name || ' ' || last_name as full_name,
                date_of_birth,
                gender,
                blood_type,
                phone
            FROM patients
            WHERE patient_number LIKE ?
            OR first_name LIKE ?
            OR last_name LIKE ?
            OR phone LIKE ?
            ORDER BY created_at DESC
            LIMIT 20
        `).all(`%${searchTerm}%`, `%${searchTerm}%`, `%${searchTerm}%`, `%${searchTerm}%`);

        return patients;
    }

    /**
     * Get patient admission history
     */
    getAdmissionHistory(patientId) {
        const db = dbConnection.getConnection();

        const history = db.prepare(`
            SELECT
                a.id,
                a.admission_date,
                a.discharge_date,
                a.admission_type,
                a.diagnosis,
                a.status,
                d.name as department_name,
                b.bed_number,
                doctor.first_name || ' ' || doctor.last_name as doctor_name
            FROM admissions a
            LEFT JOIN departments d ON a.department_id = d.id
            LEFT JOIN beds b ON a.bed_id = b.id
            LEFT JOIN staff doctor ON a.assigned_doctor_id = doctor.id
            WHERE a.patient_id = ?
            ORDER BY a.admission_date DESC
        `).all(patientId);

        return history;
    }

    /**
     * Get current active admissions
     */
    getActiveAdmissions() {
        const db = dbConnection.getConnection();

        const admissions = db.prepare(`
            SELECT
                a.id,
                a.admission_date,
                a.admission_type,
                a.priority_level,
                a.status,
                a.diagnosis,
                p.patient_number,
                p.first_name || ' ' || p.last_name as patient_name,
                p.gender,
                p.blood_type,
                d.name as department_name,
                b.bed_number,
                doctor.first_name || ' ' || doctor.last_name as doctor_name,
                nurse.first_name || ' ' || nurse.last_name as nurse_name
            FROM admissions a
            JOIN patients p ON a.patient_id = p.id
            LEFT JOIN departments d ON a.department_id = d.id
            LEFT JOIN beds b ON a.bed_id = b.id
            LEFT JOIN staff doctor ON a.assigned_doctor_id = doctor.id
            LEFT JOIN staff nurse ON a.assigned_nurse_id = nurse.id
            WHERE a.status IN ('WAITING', 'ADMITTED')
            ORDER BY a.priority_level DESC, a.admission_date ASC
        `).all();

        return admissions;
    }

    /**
     * Update patient information
     */
    updatePatient(patientId, updates) {
        const db = dbConnection.getConnection();

        try {
            const allowedFields = [
                'first_name', 'last_name', 'phone', 'email',
                'emergency_contact_name', 'emergency_contact_phone',
                'medical_history', 'allergies'
            ];

            const updateFields = Object.keys(updates)
                .filter(key => allowedFields.includes(key))
                .map(key => `${key} = ?`)
                .join(', ');

            const updateValues = Object.keys(updates)
                .filter(key => allowedFields.includes(key))
                .map(key => updates[key]);

            if (updateFields.length === 0) {
                throw new Error('No valid fields to update');
            }

            db.prepare(`
                UPDATE patients
                SET ${updateFields}, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            `).run(...updateValues, patientId);

            return {
                success: true,
                message: 'Patient information updated successfully'
            };
        } catch (error) {
            console.error('Patient update error:', error);
            throw error;
        }
    }
}

export default new PatientService();
