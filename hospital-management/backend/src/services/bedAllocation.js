import dbConnection from '../database/connection.js';

/**
 * Bed Allocation Service
 * Handles intelligent bed assignment with priority queuing and department-specific logic
 */
class BedAllocationService {
    /**
     * Allocate a bed for a patient admission
     * @param {Object} admission - Admission details
     * @returns {Object} Allocation result with bed assignment or waiting status
     */
    allocateBed(admission) {
        const db = dbConnection.getConnection();

        try {
            return db.transaction(() => {
                const { patient_id, department_id, admission_type, priority_level, diagnosis } = admission;

                // Check department capacity
                const department = db.prepare(`
                    SELECT id, name, available_beds, department_type
                    FROM departments
                    WHERE id = ?
                `).get(department_id);

                if (!department) {
                    throw new Error('Department not found');
                }

                // Determine bed type based on department and admission type
                const bedType = this.determineBedType(department.department_type, admission_type, priority_level);

                // Find available bed
                const availableBed = db.prepare(`
                    SELECT id, bed_number, bed_type
                    FROM beds
                    WHERE department_id = ?
                    AND status = 'AVAILABLE'
                    AND bed_type = ?
                    ORDER BY id ASC
                    LIMIT 1
                `).get(department_id, bedType);

                if (!availableBed) {
                    // No bed available - check if we should try alternate bed types
                    const alternateBed = this.findAlternateBed(db, department_id, bedType, priority_level);

                    if (!alternateBed) {
                        // Add to waiting queue
                        return {
                            success: false,
                            status: 'WAITING',
                            message: `No ${bedType} beds available in ${department.name}. Patient added to waiting queue.`,
                            waiting_position: this.getWaitingPosition(db, department_id, priority_level)
                        };
                    }

                    return this.assignBed(db, alternateBed.id, patient_id, admission);
                }

                return this.assignBed(db, availableBed.id, patient_id, admission);
            })();
        } catch (error) {
            console.error('Bed allocation error:', error);
            throw error;
        }
    }

    /**
     * Assign a bed to a patient
     */
    assignBed(db, bedId, patientId, admission) {
        // Update bed status
        db.prepare(`
            UPDATE beds
            SET status = 'OCCUPIED', updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        `).run(bedId);

        // Update department available beds
        db.prepare(`
            UPDATE departments
            SET available_beds = available_beds - 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        `).run(admission.department_id);

        // Create admission record
        const admissionResult = db.prepare(`
            INSERT INTO admissions (
                patient_id, bed_id, department_id, admission_type,
                priority_level, diagnosis, status, treatment_plan,
                assigned_doctor_id, assigned_nurse_id, notes
            ) VALUES (?, ?, ?, ?, ?, ?, 'ADMITTED', ?, ?, ?, ?)
        `).run(
            patientId,
            bedId,
            admission.department_id,
            admission.admission_type,
            admission.priority_level,
            admission.diagnosis,
            admission.treatment_plan,
            admission.assigned_doctor_id,
            admission.assigned_nurse_id,
            admission.notes
        );

        const bed = db.prepare('SELECT bed_number, bed_type FROM beds WHERE id = ?').get(bedId);
        const department = db.prepare('SELECT name FROM departments WHERE id = ?').get(admission.department_id);

        return {
            success: true,
            status: 'ADMITTED',
            admission_id: admissionResult.lastInsertRowid,
            bed_number: bed.bed_number,
            bed_type: bed.bed_type,
            department: department.name,
            message: `Patient successfully admitted to ${bed.bed_number}`
        };
    }

    /**
     * Determine appropriate bed type based on admission details
     */
    determineBedType(departmentType, admissionType, priorityLevel) {
        if (departmentType === 'ICU') return 'ICU';
        if (admissionType === 'EMERGENCY' && priorityLevel >= 4) return 'ICU';
        if (priorityLevel >= 4) return 'ISOLATION';
        return 'STANDARD';
    }

    /**
     * Find alternate bed if preferred type not available
     */
    findAlternateBed(db, departmentId, requestedType, priorityLevel) {
        // For high priority, check ICU beds
        if (priorityLevel >= 4 && requestedType !== 'ICU') {
            return db.prepare(`
                SELECT id, bed_number, bed_type
                FROM beds
                WHERE department_id = ?
                AND status = 'AVAILABLE'
                AND bed_type = 'ICU'
                LIMIT 1
            `).get(departmentId);
        }

        // Otherwise, accept any available bed for emergencies
        if (priorityLevel >= 3) {
            return db.prepare(`
                SELECT id, bed_number, bed_type
                FROM beds
                WHERE department_id = ?
                AND status = 'AVAILABLE'
                ORDER BY
                    CASE bed_type
                        WHEN 'ICU' THEN 1
                        WHEN 'ISOLATION' THEN 2
                        WHEN 'VENTILATOR' THEN 3
                        WHEN 'STANDARD' THEN 4
                    END
                LIMIT 1
            `).get(departmentId);
        }

        return null;
    }

    /**
     * Get position in waiting queue
     */
    getWaitingPosition(db, departmentId, priorityLevel) {
        const result = db.prepare(`
            SELECT COUNT(*) as position
            FROM admissions
            WHERE department_id = ?
            AND status = 'WAITING'
            AND priority_level >= ?
        `).get(departmentId, priorityLevel);

        return result.position + 1;
    }

    /**
     * Discharge a patient and free up bed
     */
    dischargePatient(admissionId, notes = '') {
        const db = dbConnection.getConnection();

        try {
            return db.transaction(() => {
                // Get admission details
                const admission = db.prepare(`
                    SELECT a.*
                    FROM admissions a
                    WHERE a.id = ? AND a.status = 'ADMITTED'
                `).get(admissionId);

                if (!admission) {
                    throw new Error('Active admission not found');
                }

                // Update admission status
                db.prepare(`
                    UPDATE admissions
                    SET status = 'DISCHARGED',
                        discharge_date = CURRENT_TIMESTAMP,
                        notes = ?,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                `).run(notes, admissionId);

                // Free up bed if assigned
                if (admission.bed_id) {
                    db.prepare(`
                        UPDATE beds
                        SET status = 'AVAILABLE',
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                    `).run(admission.bed_id);

                    // Update department available beds
                    db.prepare(`
                        UPDATE departments
                        SET available_beds = available_beds + 1,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                    `).run(admission.department_id);
                }

                // Check waiting queue and auto-assign
                this.processWaitingQueue(db, admission.department_id);

                return {
                    success: true,
                    message: 'Patient discharged successfully',
                    admission_id: admissionId
                };
            })();
        } catch (error) {
            console.error('Discharge error:', error);
            throw error;
        }
    }

    /**
     * Process waiting queue when bed becomes available
     */
    processWaitingQueue(db, departmentId) {
        // Find highest priority waiting patient
        const waiting = db.prepare(`
            SELECT id, patient_id, admission_type, priority_level, diagnosis
            FROM admissions
            WHERE department_id = ?
            AND status = 'WAITING'
            ORDER BY priority_level DESC, created_at ASC
            LIMIT 1
        `).get(departmentId);

        if (waiting) {
            console.log(`Auto-assigning bed to waiting patient (Admission ID: ${waiting.id})`);
            // This would trigger bed allocation for the waiting patient
            // In a real system, this would emit an event or notification
        }
    }

    /**
     * Get real-time bed availability across all departments
     */
    getBedAvailability() {
        const db = dbConnection.getConnection();

        const departments = db.prepare(`
            SELECT
                d.id,
                d.name,
                d.department_type,
                d.total_beds,
                d.available_beds,
                COUNT(CASE WHEN b.status = 'OCCUPIED' THEN 1 END) as occupied_beds,
                COUNT(CASE WHEN b.status = 'MAINTENANCE' THEN 1 END) as maintenance_beds,
                ROUND(CAST(d.available_beds AS FLOAT) / d.total_beds * 100, 1) as availability_percentage
            FROM departments d
            LEFT JOIN beds b ON d.id = b.department_id
            GROUP BY d.id
            ORDER BY d.department_type, d.name
        `).all();

        return departments;
    }

    /**
     * Get detailed bed status for a department
     */
    getDepartmentBedStatus(departmentId) {
        const db = dbConnection.getConnection();

        const beds = db.prepare(`
            SELECT
                b.id,
                b.bed_number,
                b.bed_type,
                b.status,
                p.first_name || ' ' || p.last_name as patient_name,
                a.admission_date,
                a.diagnosis,
                s.first_name || ' ' || s.last_name as assigned_doctor
            FROM beds b
            LEFT JOIN admissions a ON b.id = a.bed_id AND a.status = 'ADMITTED'
            LEFT JOIN patients p ON a.patient_id = p.id
            LEFT JOIN staff s ON a.assigned_doctor_id = s.id
            WHERE b.department_id = ?
            ORDER BY b.bed_number
        `).all(departmentId);

        return beds;
    }
}

export default new BedAllocationService();
