import { useState, useEffect } from 'react';
import StaffManagement from './components/StaffManagement';
import PatientSearch from './components/PatientSearch';

const API_URL = '/api';

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [stats, setStats] = useState(null);
  const [bedAvailability, setBedAvailability] = useState([]);
  const [activeAdmissions, setActiveAdmissions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  // Fetch dashboard data
  const fetchDashboardData = async () => {
    try {
      const [statsRes, bedsRes, admissionsRes] = await Promise.all([
        fetch(`${API_URL}/dashboard/stats`),
        fetch(`${API_URL}/beds/availability`),
        fetch(`${API_URL}/admissions/active`)
      ]);

      const [statsData, bedsData, admissionsData] = await Promise.all([
        statsRes.json(),
        bedsRes.json(),
        admissionsRes.json()
      ]);

      setStats(statsData);
      setBedAvailability(bedsData);
      setActiveAdmissions(admissionsData);
      setLastUpdate(new Date());
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error);
      setLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'dashboard') {
      fetchDashboardData();
      // Auto-refresh every 30 seconds only on dashboard
      const interval = setInterval(fetchDashboardData, 30000);
      return () => clearInterval(interval);
    }
  }, [activeTab]);

  if (loading && activeTab === 'dashboard') {
    return (
      <div className="loading">
        <div className="spinner"></div>
        <p>Loading Hospital Management System...</p>
      </div>
    );
  }

  return (
    <div className="app">
      <header className="header">
        <div className="header-content">
          <h1>🏥 Hospital Management System</h1>
          <div className="header-info">
            <span className="status-indicator active"></span>
            <span>System Active</span>
            <span className="divider">|</span>
            <span>Last updated: {lastUpdate.toLocaleTimeString()}</span>
            {activeTab === 'dashboard' && (
              <button onClick={fetchDashboardData} className="refresh-btn">
                🔄 Refresh
              </button>
            )}
          </div>
        </div>
      </header>

      <nav className="tabs">
        <button
          className={activeTab === 'dashboard' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('dashboard')}
        >
          📊 Dashboard
        </button>
        <button
          className={activeTab === 'patients' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('patients')}
        >
          🔍 Patient Search
        </button>
        <button
          className={activeTab === 'staff' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('staff')}
        >
          👥 Staff Management
        </button>
        <button
          className={activeTab === 'analytics' ? 'tab active' : 'tab'}
          onClick={() => setActiveTab('analytics')}
        >
          📈 Analytics
        </button>
      </nav>

      <main className="main-content">
        {activeTab === 'dashboard' && (
          <DashboardTab
            stats={stats}
            bedAvailability={bedAvailability}
            activeAdmissions={activeAdmissions}
          />
        )}

        {activeTab === 'patients' && <PatientSearch />}

        {activeTab === 'staff' && <StaffManagement />}

        {activeTab === 'analytics' && (
          <AnalyticsTab
            stats={stats}
            bedAvailability={bedAvailability}
            activeAdmissions={activeAdmissions}
          />
        )}
      </main>
    </div>
  );
}

function DashboardTab({ stats, bedAvailability, activeAdmissions }) {
  return (
    <>
      {/* Stats Cards */}
      <section className="stats-grid">
        <StatCard
          title="Total Patients"
          value={stats?.total_patients || 0}
          icon="👥"
          color="blue"
        />
        <StatCard
          title="Active Admissions"
          value={stats?.active_admissions || 0}
          icon="🛏️"
          color="green"
        />
        <StatCard
          title="Available Beds"
          value={`${stats?.available_beds || 0} / ${stats?.total_beds || 0}`}
          icon="✅"
          color="purple"
        />
        <StatCard
          title="Occupancy Rate"
          value={`${stats?.occupancy_rate || 0}%`}
          icon="📊"
          color={stats?.occupancy_rate > 80 ? 'red' : 'orange'}
        />
        <StatCard
          title="Emergency Cases"
          value={stats?.emergency_cases || 0}
          icon="🚨"
          color="red"
          pulse={stats?.emergency_cases > 0}
        />
        <StatCard
          title="Waiting Queue"
          value={stats?.waiting_queue || 0}
          icon="⏳"
          color="yellow"
        />
      </section>

      {/* Bed Availability */}
      <section className="section">
        <h2>🛏️ Bed Availability by Department</h2>
        <div className="bed-availability-grid">
          {bedAvailability.map(dept => (
            <DepartmentCard key={dept.id} department={dept} />
          ))}
        </div>
      </section>

      {/* Active Admissions */}
      <section className="section">
        <h2>📋 Active Admissions</h2>
        <div className="admissions-table">
          <table>
            <thead>
              <tr>
                <th>Patient</th>
                <th>Patient #</th>
                <th>Department</th>
                <th>Bed</th>
                <th>Admission Type</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Doctor</th>
                <th>Admission Date</th>
              </tr>
            </thead>
            <tbody>
              {activeAdmissions.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: 'center', padding: '2rem' }}>
                    No active admissions
                  </td>
                </tr>
              ) : (
                activeAdmissions.map(admission => (
                  <tr key={admission.id} className={admission.status === 'WAITING' ? 'waiting' : ''}>
                    <td>
                      <strong>{admission.patient_name}</strong>
                      <br />
                      <small>{admission.gender} | {admission.blood_type}</small>
                    </td>
                    <td>{admission.patient_number}</td>
                    <td>{admission.department_name}</td>
                    <td>{admission.bed_number || 'Waiting'}</td>
                    <td>
                      <span className={`badge ${admission.admission_type.toLowerCase()}`}>
                        {admission.admission_type}
                      </span>
                    </td>
                    <td>
                      <span className={`priority priority-${admission.priority_level}`}>
                        Level {admission.priority_level}
                      </span>
                    </td>
                    <td>
                      <span className={`status ${admission.status.toLowerCase()}`}>
                        {admission.status}
                      </span>
                    </td>
                    <td>{admission.doctor_name || 'Unassigned'}</td>
                    <td>{new Date(admission.admission_date).toLocaleString()}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}

function AnalyticsTab({ stats, bedAvailability, activeAdmissions }) {
  return (
    <div className="analytics-container">
      <h2>📈 Hospital Analytics</h2>

      <div className="analytics-grid">
        <div className="analytics-card">
          <h3>Bed Utilization</h3>
          <div className="chart-placeholder">
            {bedAvailability.map(dept => (
              <div key={dept.id} className="bar-chart-item">
                <div className="bar-label">{dept.name}</div>
                <div className="bar-container">
                  <div
                    className="bar-fill"
                    style={{
                      width: `${((dept.total_beds - dept.available_beds) / dept.total_beds * 100)}%`,
                      background: dept.available_beds === 0 ? '#ef4444' : dept.availability_percentage < 30 ? '#f59e0b' : '#10b981'
                    }}
                  >
                    <span className="bar-value">
                      {dept.total_beds - dept.available_beds}/{dept.total_beds}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="analytics-card">
          <h3>Admission Types Distribution</h3>
          <div className="stats-breakdown">
            {activeAdmissions.reduce((acc, admission) => {
              acc[admission.admission_type] = (acc[admission.admission_type] || 0) + 1;
              return acc;
            }, {})}
            <div className="breakdown-item emergency">
              <div className="breakdown-label">🚨 Emergency</div>
              <div className="breakdown-value">
                {activeAdmissions.filter(a => a.admission_type === 'EMERGENCY').length}
              </div>
            </div>
            <div className="breakdown-item scheduled">
              <div className="breakdown-label">📅 Scheduled</div>
              <div className="breakdown-value">
                {activeAdmissions.filter(a => a.admission_type === 'SCHEDULED').length}
              </div>
            </div>
            <div className="breakdown-item transfer">
              <div className="breakdown-label">🔄 Transfer</div>
              <div className="breakdown-value">
                {activeAdmissions.filter(a => a.admission_type === 'TRANSFER').length}
              </div>
            </div>
          </div>
        </div>

        <div className="analytics-card">
          <h3>Priority Levels</h3>
          <div className="priority-chart">
            {[5, 4, 3, 2, 1].map(level => (
              <div key={level} className="priority-bar-item">
                <div className="priority-bar-label">Priority {level}</div>
                <div className="priority-bar-container">
                  <div
                    className={`priority-bar-fill priority-${level}`}
                    style={{
                      width: `${(activeAdmissions.filter(a => a.priority_level === level).length / Math.max(activeAdmissions.length, 1) * 100)}%`
                    }}
                  >
                    <span>{activeAdmissions.filter(a => a.priority_level === level).length}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="analytics-card">
          <h3>System Overview</h3>
          <div className="overview-stats">
            <div className="overview-item">
              <div className="overview-icon">👥</div>
              <div className="overview-data">
                <div className="overview-value">{stats?.total_patients || 0}</div>
                <div className="overview-label">Total Patients</div>
              </div>
            </div>
            <div className="overview-item">
              <div className="overview-icon">🛏️</div>
              <div className="overview-data">
                <div className="overview-value">{stats?.total_beds || 0}</div>
                <div className="overview-label">Total Beds</div>
              </div>
            </div>
            <div className="overview-item">
              <div className="overview-icon">📊</div>
              <div className="overview-data">
                <div className="overview-value">{stats?.occupancy_rate || 0}%</div>
                <div className="overview-label">Occupancy</div>
              </div>
            </div>
            <div className="overview-item">
              <div className="overview-icon">📅</div>
              <div className="overview-data">
                <div className="overview-value">{stats?.recent_admissions || 0}</div>
                <div className="overview-label">24h Admissions</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, icon, color, pulse }) {
  return (
    <div className={`stat-card ${color} ${pulse ? 'pulse' : ''}`}>
      <div className="stat-icon">{icon}</div>
      <div className="stat-content">
        <div className="stat-value">{value}</div>
        <div className="stat-title">{title}</div>
      </div>
    </div>
  );
}

function DepartmentCard({ department }) {
  const occupancyRate = ((department.total_beds - department.available_beds) / department.total_beds) * 100;
  const getStatusColor = () => {
    if (occupancyRate >= 90) return 'critical';
    if (occupancyRate >= 70) return 'warning';
    return 'good';
  };

  return (
    <div className={`department-card ${getStatusColor()}`}>
      <div className="department-header">
        <h3>{department.name}</h3>
        <span className="department-type">{department.department_type}</span>
      </div>
      <div className="department-stats">
        <div className="bed-count">
          <div className="available">{department.available_beds}</div>
          <div className="total">/ {department.total_beds} beds</div>
        </div>
        <div className="occupancy-bar">
          <div
            className="occupancy-fill"
            style={{ width: `${occupancyRate}%` }}
          ></div>
        </div>
        <div className="occupancy-label">
          {occupancyRate.toFixed(0)}% Occupied
        </div>
      </div>
      {department.occupied_beds > 0 && (
        <div className="department-details">
          <span>🛏️ Occupied: {department.occupied_beds}</span>
          {department.maintenance_beds > 0 && (
            <span>🔧 Maintenance: {department.maintenance_beds}</span>
          )}
        </div>
      )}
    </div>
  );
}

export default App;
