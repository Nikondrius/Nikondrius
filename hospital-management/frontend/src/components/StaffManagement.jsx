import { useState, useEffect } from 'react';

const API_URL = '/api';

function StaffManagement() {
  const [staff, setStaff] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [filterRole, setFilterRole] = useState('ALL');
  const [formData, setFormData] = useState({
    first_name: '',
    last_name: '',
    role: 'DOCTOR',
    specialization: '',
    department_id: '',
    phone: '',
    email: ''
  });

  useEffect(() => {
    fetchStaff();
    fetchDepartments();
  }, [filterRole]);

  const fetchStaff = async () => {
    try {
      const url = filterRole === 'ALL'
        ? `${API_URL}/staff`
        : `${API_URL}/staff?role=${filterRole}`;
      const response = await fetch(url);
      const data = await response.json();
      setStaff(data);
    } catch (error) {
      console.error('Failed to fetch staff:', error);
    }
  };

  const fetchDepartments = async () => {
    try {
      const response = await fetch(`${API_URL}/departments`);
      const data = await response.json();
      setDepartments(data);
    } catch (error) {
      console.error('Failed to fetch departments:', error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch(`${API_URL}/staff`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          department_id: formData.department_id ? parseInt(formData.department_id) : null
        })
      });

      if (response.ok) {
        setShowForm(false);
        setFormData({
          first_name: '',
          last_name: '',
          role: 'DOCTOR',
          specialization: '',
          department_id: '',
          phone: '',
          email: ''
        });
        fetchStaff();
      }
    } catch (error) {
      console.error('Failed to register staff:', error);
    }
  };

  const getRoleIcon = (role) => {
    const icons = {
      DOCTOR: '👨‍⚕️',
      NURSE: '👩‍⚕️',
      ADMIN: '👔',
      TECHNICIAN: '🔬'
    };
    return icons[role] || '👤';
  };

  const getRoleColor = (role) => {
    const colors = {
      DOCTOR: 'role-doctor',
      NURSE: 'role-nurse',
      ADMIN: 'role-admin',
      TECHNICIAN: 'role-tech'
    };
    return colors[role] || '';
  };

  return (
    <div className="staff-management">
      <div className="staff-header">
        <h2>👥 Staff Management</h2>
        <button onClick={() => setShowForm(!showForm)} className="btn-primary">
          {showForm ? '✕ Cancel' : '+ Register New Staff'}
        </button>
      </div>

      {showForm && (
        <div className="staff-form-card">
          <h3>Register New Staff Member</h3>
          <form onSubmit={handleSubmit} className="staff-form">
            <div className="form-row">
              <div className="form-group">
                <label>First Name *</label>
                <input
                  type="text"
                  required
                  value={formData.first_name}
                  onChange={(e) => setFormData({...formData, first_name: e.target.value})}
                />
              </div>
              <div className="form-group">
                <label>Last Name *</label>
                <input
                  type="text"
                  required
                  value={formData.last_name}
                  onChange={(e) => setFormData({...formData, last_name: e.target.value})}
                />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Role *</label>
                <select
                  required
                  value={formData.role}
                  onChange={(e) => setFormData({...formData, role: e.target.value})}
                >
                  <option value="DOCTOR">Doctor</option>
                  <option value="NURSE">Nurse</option>
                  <option value="ADMIN">Administrator</option>
                  <option value="TECHNICIAN">Technician</option>
                </select>
              </div>
              <div className="form-group">
                <label>Specialization</label>
                <input
                  type="text"
                  placeholder="e.g., Cardiology, Emergency Medicine"
                  value={formData.specialization}
                  onChange={(e) => setFormData({...formData, specialization: e.target.value})}
                />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Department</label>
                <select
                  value={formData.department_id}
                  onChange={(e) => setFormData({...formData, department_id: e.target.value})}
                >
                  <option value="">Unassigned</option>
                  {departments.map(dept => (
                    <option key={dept.id} value={dept.id}>{dept.name}</option>
                  ))}
                </select>
              </div>
              <div className="form-group">
                <label>Phone</label>
                <input
                  type="tel"
                  placeholder="555-0123"
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                />
              </div>
            </div>

            <div className="form-group">
              <label>Email *</label>
              <input
                type="email"
                required
                placeholder="doctor@hospital.com"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
              />
            </div>

            <button type="submit" className="btn-submit">Register Staff Member</button>
          </form>
        </div>
      )}

      <div className="staff-filters">
        <button
          className={filterRole === 'ALL' ? 'filter-btn active' : 'filter-btn'}
          onClick={() => setFilterRole('ALL')}
        >
          All Staff
        </button>
        <button
          className={filterRole === 'DOCTOR' ? 'filter-btn active' : 'filter-btn'}
          onClick={() => setFilterRole('DOCTOR')}
        >
          👨‍⚕️ Doctors
        </button>
        <button
          className={filterRole === 'NURSE' ? 'filter-btn active' : 'filter-btn'}
          onClick={() => setFilterRole('NURSE')}
        >
          👩‍⚕️ Nurses
        </button>
        <button
          className={filterRole === 'ADMIN' ? 'filter-btn active' : 'filter-btn'}
          onClick={() => setFilterRole('ADMIN')}
        >
          👔 Admin
        </button>
        <button
          className={filterRole === 'TECHNICIAN' ? 'filter-btn active' : 'filter-btn'}
          onClick={() => setFilterRole('TECHNICIAN')}
        >
          🔬 Technicians
        </button>
      </div>

      <div className="staff-grid">
        {staff.length === 0 ? (
          <div className="no-staff">
            <p>No staff members found.</p>
            <p>Click "Register New Staff" to add staff members.</p>
          </div>
        ) : (
          staff.map(member => (
            <div key={member.id} className={`staff-card ${getRoleColor(member.role)}`}>
              <div className="staff-icon">{getRoleIcon(member.role)}</div>
              <div className="staff-info">
                <h3>{member.full_name}</h3>
                <div className="staff-role">{member.role}</div>
                {member.specialization && (
                  <div className="staff-specialization">{member.specialization}</div>
                )}
                {member.department_name && (
                  <div className="staff-department">📍 {member.department_name}</div>
                )}
                <div className="staff-status">{member.status}</div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default StaffManagement;
