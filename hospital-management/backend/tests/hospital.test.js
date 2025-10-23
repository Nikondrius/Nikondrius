// Use test database - MUST be set before imports
process.env.DB_PATH = './test-hospital.db';

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { unlink } from 'node:fs/promises';
import { initializeDatabase } from '../src/database/init.js';
import dbConnection from '../src/database/connection.js';
import patientService from '../src/services/patientService.js';
import bedAllocationService from '../src/services/bedAllocation.js';

describe('Hospital Management System Tests', () => {
  let testPatientId;
  let testAdmissionId;

  before(async () => {
    console.log('Setting up test database...');
    // Ensure clean test database
    try {
      await unlink('./test-hospital.db');
    } catch (e) {
      // File might not exist, that's ok
    }
    // Explicitly initialize database
    initializeDatabase('./test-hospital.db');
  });

  after(async () => {
    console.log('Cleaning up test database...');
    dbConnection.close();
    try {
      await unlink('./test-hospital.db');
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  describe('Patient Registration', () => {
    it('should register a new patient successfully', () => {
      const patientData = {
        first_name: 'John',
        last_name: 'Doe',
        date_of_birth: '1985-05-15',
        gender: 'M',
        blood_type: 'A+',
        phone: '555-0123',
        email: 'john.doe@example.com',
        emergency_contact_name: 'Jane Doe',
        emergency_contact_phone: '555-0124',
        medical_history: 'No known conditions',
        allergies: 'None'
      };

      const result = patientService.registerPatient(patientData);

      assert.ok(result.success, 'Patient registration should succeed');
      assert.ok(result.patient_id, 'Should return patient ID');
      assert.ok(result.patient_number, 'Should generate patient number');
      assert.match(result.patient_number, /^P-\d{8}-\d{4}$/, 'Patient number should match format P-YYYYMMDD-####');

      testPatientId = result.patient_id;
    });

    it('should generate unique patient numbers', () => {
      const patient1 = patientService.registerPatient({
        first_name: 'Test',
        last_name: 'User1',
        date_of_birth: '1990-01-01',
        gender: 'F',
        blood_type: 'O+',
        phone: '555-0001',
        email: 'test1@example.com'
      });

      const patient2 = patientService.registerPatient({
        first_name: 'Test',
        last_name: 'User2',
        date_of_birth: '1990-01-01',
        gender: 'F',
        blood_type: 'O+',
        phone: '555-0002',
        email: 'test2@example.com'
      });

      assert.notStrictEqual(
        patient1.patient_number,
        patient2.patient_number,
        'Patient numbers should be unique'
      );
    });

    it('should retrieve patient details', () => {
      const patient = patientService.getPatient(testPatientId);

      assert.strictEqual(patient.first_name, 'John');
      assert.strictEqual(patient.last_name, 'Doe');
      assert.strictEqual(patient.blood_type, 'A+');
    });

    it('should search patients by name', () => {
      const results = patientService.searchPatients('John');

      assert.ok(results.length > 0, 'Should find at least one patient');
      assert.ok(
        results.some(p => p.full_name.includes('John')),
        'Should include John in results'
      );
    });
  });

  describe('Bed Allocation', () => {
    it('should show initial bed availability', () => {
      const availability = bedAllocationService.getBedAvailability();

      assert.ok(Array.isArray(availability), 'Should return array of departments');
      assert.ok(availability.length > 0, 'Should have departments');

      const icu = availability.find(d => d.department_type === 'ICU');
      assert.ok(icu, 'Should have ICU department');
      assert.ok(icu.available_beds > 0, 'ICU should have available beds');
    });

    it('should allocate bed for emergency admission', () => {
      const admissionData = {
        patient_id: testPatientId,
        department_id: 1, // Emergency Department
        admission_type: 'EMERGENCY',
        priority_level: 5,
        diagnosis: 'Chest pain, suspected MI',
        treatment_plan: 'Immediate cardiac workup'
      };

      const result = patientService.admitPatient(admissionData);

      assert.ok(result.success, 'Emergency admission should succeed');
      assert.strictEqual(result.status, 'ADMITTED', 'Patient should be admitted');
      assert.ok(result.bed_number, 'Should assign bed number');
      assert.ok(result.admission_id, 'Should return admission ID');

      testAdmissionId = result.admission_id;
    });

    it('should update bed availability after admission', () => {
      const availability = bedAllocationService.getBedAvailability();
      const emergencyDept = availability.find(d => d.id === 1);

      // Should have one less available bed
      assert.ok(
        emergencyDept.available_beds < emergencyDept.total_beds,
        'Available beds should decrease after admission'
      );
      assert.ok(
        emergencyDept.occupied_beds > 0,
        'Should have occupied beds'
      );
    });

    it('should prevent double admission', () => {
      const admissionData = {
        patient_id: testPatientId,
        department_id: 2,
        admission_type: 'SCHEDULED',
        priority_level: 2,
        diagnosis: 'Follow-up'
      };

      assert.throws(
        () => patientService.admitPatient(admissionData),
        /already has an active admission/,
        'Should prevent double admission'
      );
    });

    it('should get active admissions list', () => {
      const admissions = patientService.getActiveAdmissions();

      assert.ok(Array.isArray(admissions), 'Should return array');
      assert.ok(admissions.length > 0, 'Should have active admissions');

      const testAdmission = admissions.find(a => a.id === testAdmissionId);
      assert.ok(testAdmission, 'Should include our test admission');
      assert.strictEqual(testAdmission.status, 'ADMITTED');
    });
  });

  describe('Patient Discharge', () => {
    it('should discharge patient and free bed', () => {
      const availabilityBefore = bedAllocationService.getBedAvailability();
      const emergencyDeptBefore = availabilityBefore.find(d => d.id === 1);

      const result = bedAllocationService.dischargePatient(
        testAdmissionId,
        'Patient stable, discharged home'
      );

      assert.ok(result.success, 'Discharge should succeed');

      const availabilityAfter = bedAllocationService.getBedAvailability();
      const emergencyDeptAfter = availabilityAfter.find(d => d.id === 1);

      assert.strictEqual(
        emergencyDeptAfter.available_beds,
        emergencyDeptBefore.available_beds + 1,
        'Available beds should increase after discharge'
      );
    });

    it('should show patient in admission history', () => {
      const history = patientService.getAdmissionHistory(testPatientId);

      assert.ok(Array.isArray(history), 'Should return array');
      assert.ok(history.length > 0, 'Should have admission history');

      const dischargedAdmission = history.find(a => a.id === testAdmissionId);
      assert.ok(dischargedAdmission, 'Should include discharged admission');
      assert.strictEqual(dischargedAdmission.status, 'DISCHARGED');
      assert.ok(dischargedAdmission.discharge_date, 'Should have discharge date');
    });
  });

  describe('Priority Queue Management', () => {
    it('should handle waiting queue when no beds available', async () => {
      // First, fill up ICU department (15 beds)
      const icuDepartmentId = 2;
      const admittedPatients = [];

      for (let i = 0; i < 15; i++) {
        const patient = patientService.registerPatient({
          first_name: `Patient`,
          last_name: `ICU${i}`,
          date_of_birth: '1980-01-01',
          gender: 'M',
          blood_type: 'O+',
          phone: `555-${1000 + i}`
        });

        const admission = patientService.admitPatient({
          patient_id: patient.patient_id,
          department_id: icuDepartmentId,
          admission_type: 'EMERGENCY',
          priority_level: 3,
          diagnosis: 'Test case'
        });

        admittedPatients.push({ patient, admission });
      }

      // Now try to admit one more - should go to waiting queue
      const waitingPatient = patientService.registerPatient({
        first_name: 'Waiting',
        last_name: 'Patient',
        date_of_birth: '1985-06-15',
        gender: 'F',
        blood_type: 'A+',
        phone: '555-9999'
      });

      const waitingResult = patientService.admitPatient({
        patient_id: waitingPatient.patient_id,
        department_id: icuDepartmentId,
        admission_type: 'SCHEDULED',
        priority_level: 2,
        diagnosis: 'Elective procedure'
      });

      assert.strictEqual(waitingResult.success, false, 'Should not get bed immediately');
      assert.strictEqual(waitingResult.status, 'WAITING', 'Should be in waiting status');
      assert.ok(waitingResult.waiting_position, 'Should have waiting position');

      // Verify ICU is full
      const availability = bedAllocationService.getBedAvailability();
      const icu = availability.find(d => d.id === icuDepartmentId);
      assert.strictEqual(icu.available_beds, 0, 'ICU should have no available beds');
    });
  });

  describe('Department Statistics', () => {
    it('should calculate occupancy rates correctly', () => {
      const availability = bedAllocationService.getBedAvailability();

      for (const dept of availability) {
        const expectedOccupancyRate = parseFloat(
          ((dept.total_beds - dept.available_beds) / dept.total_beds * 100).toFixed(1)
        );

        assert.strictEqual(
          dept.availability_percentage,
          parseFloat(((dept.available_beds / dept.total_beds) * 100).toFixed(1)),
          `${dept.name} availability percentage should be correct`
        );
      }
    });
  });

  describe('Patient Information Management', () => {
    it('should update patient information', () => {
      const updates = {
        phone: '555-9876',
        email: 'john.doe.updated@example.com',
        allergies: 'Penicillin'
      };

      const result = patientService.updatePatient(testPatientId, updates);

      assert.ok(result.success, 'Update should succeed');

      const updatedPatient = patientService.getPatient(testPatientId);
      assert.strictEqual(updatedPatient.phone, '555-9876');
      assert.strictEqual(updatedPatient.email, 'john.doe.updated@example.com');
      assert.strictEqual(updatedPatient.allergies, 'Penicillin');
    });
  });
});

console.log('\n🏥 Hospital Management System - Test Suite\n');
