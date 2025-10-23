import { useState } from 'react';

const API_URL = '/api';

function PatientSearch() {
  const [searchTerm, setSearchTerm] = useState('');
  const [patients, setPatients] = useState([]);
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [admissionHistory, setAdmissionHistory] = useState([]);
  const [loading, setLoading] = useState(false);

  const searchPatients = async (term) => {
    if (!term || term.length < 2) {
      setPatients([]);
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/patients/search?q=${encodeURIComponent(term)}`);
      const data = await response.json();
      setPatients(data);
    } catch (error) {
      console.error('Search failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (e) => {
    const value = e.target.value;
    setSearchTerm(value);
    searchPatients(value);
  };

  const selectPatient = async (patient) => {
    setSelectedPatient(patient);

    // Fetch admission history
    try {
      const response = await fetch(`${API_URL}/patients/${patient.id}/admissions`);
      const data = await response.json();
      setAdmissionHistory(data);
    } catch (error) {
      console.error('Failed to fetch admission history:', error);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      WAITING: 'status-waiting',
      ADMITTED: 'status-admitted',
      DISCHARGED: 'status-discharged',
      TRANSFERRED: 'status-transferred'
    };
    return colors[status] || '';
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const calculateAge = (dob) => {
    const birthDate = new Date(dob);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    return age;
  };

  return (
    <div className="patient-search">
      <div className="search-header">
        <h2>🔍 Patient Search</h2>
      </div>

      <div className="search-box">
        <input
          type="text"
          placeholder="Search by name, patient number, or phone..."
          value={searchTerm}
          onChange={handleSearch}
          className="search-input"
        />
        {loading && <div className="search-spinner">⌛</div>}
      </div>

      <div className="search-results-container">
        <div className="search-results">
          {patients.length > 0 && (
            <>
              <h3>Search Results ({patients.length})</h3>
              <div className="patient-list">
                {patients.map(patient => (
                  <div
                    key={patient.id}
                    className={`patient-item ${selectedPatient?.id === patient.id ? 'selected' : ''}`}
                    onClick={() => selectPatient(patient)}
                  >
                    <div className="patient-item-header">
                      <strong>{patient.full_name}</strong>
                      <span className="patient-number">{patient.patient_number}</span>
                    </div>
                    <div className="patient-item-details">
                      <span>📅 {patient.date_of_birth}</span>
                      <span>🩸 {patient.blood_type}</span>
                      <span>📞 {patient.phone}</span>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}

          {searchTerm && patients.length === 0 && !loading && (
            <div className="no-results">
              <p>No patients found matching "{searchTerm}"</p>
            </div>
          )}

          {!searchTerm && (
            <div className="search-prompt">
              <p>💡 Start typing to search for patients</p>
              <p>Search by name, patient number, or phone number</p>
            </div>
          )}
        </div>

        {selectedPatient && (
          <div className="patient-details">
            <div className="patient-info-card">
              <h3>Patient Information</h3>
              <div className="info-grid">
                <div className="info-item">
                  <label>Full Name</label>
                  <div>{selectedPatient.full_name}</div>
                </div>
                <div className="info-item">
                  <label>Patient Number</label>
                  <div>{selectedPatient.patient_number}</div>
                </div>
                <div className="info-item">
                  <label>Date of Birth</label>
                  <div>{selectedPatient.date_of_birth} ({calculateAge(selectedPatient.date_of_birth)} years old)</div>
                </div>
                <div className="info-item">
                  <label>Gender</label>
                  <div>{selectedPatient.gender === 'M' ? 'Male' : selectedPatient.gender === 'F' ? 'Female' : 'Other'}</div>
                </div>
                <div className="info-item">
                  <label>Blood Type</label>
                  <div>🩸 {selectedPatient.blood_type}</div>
                </div>
                <div className="info-item">
                  <label>Phone</label>
                  <div>📞 {selectedPatient.phone}</div>
                </div>
              </div>

              {selectedPatient.allergies && (
                <div className="alert-box warning">
                  <strong>⚠️ Allergies:</strong> {selectedPatient.allergies}
                </div>
              )}

              {selectedPatient.medical_history && (
                <div className="info-section">
                  <label>Medical History</label>
                  <div>{selectedPatient.medical_history}</div>
                </div>
              )}

              {selectedPatient.emergency_contact_name && (
                <div className="info-section">
                  <label>Emergency Contact</label>
                  <div>
                    {selectedPatient.emergency_contact_name}<br />
                    📞 {selectedPatient.emergency_contact_phone}
                  </div>
                </div>
              )}
            </div>

            <div className="admission-history-card">
              <h3>Admission History</h3>
              {admissionHistory.length === 0 ? (
                <p className="no-history">No admission history</p>
              ) : (
                <div className="admission-timeline">
                  {admissionHistory.map(admission => (
                    <div key={admission.id} className="timeline-item">
                      <div className={`timeline-marker ${getStatusColor(admission.status)}`}></div>
                      <div className="timeline-content">
                        <div className="timeline-header">
                          <strong>{admission.department_name}</strong>
                          <span className={`status-badge ${getStatusColor(admission.status)}`}>
                            {admission.status}
                          </span>
                        </div>
                        <div className="timeline-details">
                          <div>📅 Admitted: {formatDate(admission.admission_date)}</div>
                          {admission.discharge_date && (
                            <div>🏠 Discharged: {formatDate(admission.discharge_date)}</div>
                          )}
                          {admission.bed_number && (
                            <div>🛏️ Bed: {admission.bed_number}</div>
                          )}
                          {admission.doctor_name && (
                            <div>👨‍⚕️ Doctor: {admission.doctor_name}</div>
                          )}
                          <div className="timeline-diagnosis">
                            <strong>Diagnosis:</strong> {admission.diagnosis}
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

export default PatientSearch;
