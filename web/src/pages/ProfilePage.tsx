import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Navbar from '../components/Navbar';
import api from '../lib/api';

export default function ProfilePage() {
  const navigate = useNavigate();
  const [loading,  setLoading]  = useState(false);
  const [saved,    setSaved]    = useState(false);
  const [error,    setError]    = useState('');
  const [form, setForm] = useState({
    diabetes_type:  'type2',
    age:            '',
    weight_kg:      '',
    height_cm:      '',
    activity_level: 'moderate',
    medications:    '',
    conditions:     '',
  });

  // Load existing profile on mount
  useEffect(() => {
    api.get('/users/profile').then((res: any) => {
      if (res.data.diabetes_type) {
        setForm({
          diabetes_type:  res.data.diabetes_type,
          age:            res.data.age?.toString() || '',
          weight_kg:      res.data.weight_kg?.toString() || '',
          height_cm:      res.data.height_cm?.toString() || '',
          activity_level: res.data.activity_level,
          medications:    res.data.medications || '',
          conditions:     res.data.conditions || '',
        });
      }
    }).catch(() => {});
  }, []);

  const handleSave = async () => {
    setLoading(true);
    setError('');
    setSaved(false);
    try {
      await api.post('/users/profile', {
        diabetes_type:  form.diabetes_type,
        age:            parseInt(form.age),
        weight_kg:      parseFloat(form.weight_kg),
        height_cm:      parseFloat(form.height_cm),
        activity_level: form.activity_level,
        medications:    form.medications,
        conditions:     form.conditions,
      });
      setSaved(true);
      setTimeout(() => navigate('/dashboard'), 1500);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to save profile');
    } finally {
      setLoading(false);
    }
  };

  const update = (field: string, value: string) =>
    setForm(prev => ({ ...prev, [field]: value }));

  return (
    <div style={{ backgroundColor: '#f0f4f8', minHeight: '100vh' }}>
      <Navbar />
      <div style={styles.container}>
        <div style={styles.card}>
          <h2 style={styles.title}>Medical Profile</h2>
          <p style={styles.subtitle}>
            This information personalises your glucose predictions
          </p>

          {error  && <div style={styles.error}>{error}</div>}
          {saved  && <div style={styles.success}>Profile saved! Redirecting...</div>}

          <div style={styles.grid}>
            <div style={styles.field}>
              <label style={styles.label}>Diabetes Type</label>
              <select
                style={styles.input}
                value={form.diabetes_type}
                onChange={e => update('diabetes_type', e.target.value)}
              >
                <option value="type1">Type 1</option>
                <option value="type2">Type 2</option>
                <option value="prediabetes">Prediabetes</option>
              </select>
            </div>

            <div style={styles.field}>
              <label style={styles.label}>Activity Level</label>
              <select
                style={styles.input}
                value={form.activity_level}
                onChange={e => update('activity_level', e.target.value)}
              >
                <option value="sedentary">Sedentary</option>
                <option value="light">Light</option>
                <option value="moderate">Moderate</option>
                <option value="active">Active</option>
              </select>
            </div>

            <div style={styles.field}>
              <label style={styles.label}>Age</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 25"
                value={form.age}
                onChange={e => update('age', e.target.value)}
              />
            </div>

            <div style={styles.field}>
              <label style={styles.label}>Weight (kg)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 70"
                value={form.weight_kg}
                onChange={e => update('weight_kg', e.target.value)}
              />
            </div>

            <div style={styles.field}>
              <label style={styles.label}>Height (cm)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 175"
                value={form.height_cm}
                onChange={e => update('height_cm', e.target.value)}
              />
            </div>
          </div>

          <div style={styles.field}>
            <label style={styles.label}>Current Medications</label>
            <textarea
              style={{ ...styles.input, height: '80px', resize: 'vertical' }}
              placeholder="e.g. Metformin 500mg, Insulin"
              value={form.medications}
              onChange={e => update('medications', e.target.value)}
            />
          </div>

          <div style={styles.field}>
            <label style={styles.label}>Other Medical Conditions</label>
            <textarea
              style={{ ...styles.input, height: '80px', resize: 'vertical' }}
              placeholder="e.g. Hypertension, High cholesterol"
              value={form.conditions}
              onChange={e => update('conditions', e.target.value)}
            />
          </div>

          <button
            style={styles.button}
            onClick={handleSave}
            disabled={loading}
          >
            {loading ? 'Saving...' : 'Save Profile'}
          </button>
        </div>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    maxWidth: '700px',
    margin:   '2rem auto',
    padding:  '0 1rem',
  },
  card: {
    backgroundColor: 'white',
    borderRadius:    '12px',
    padding:         '2rem',
    boxShadow:       '0 2px 12px rgba(0,0,0,0.08)',
  },
  title: {
    color:      '#1F3864',
    margin:     '0 0 0.5rem',
    fontSize:   '22px',
  },
  subtitle: {
    color:     '#666',
    fontSize:  '13px',
    margin:    '0 0 1.5rem',
  },
  grid: {
    display:             'grid',
    gridTemplateColumns: '1fr 1fr',
    gap:                 '1rem',
    marginBottom:        '1rem',
  },
  field: {
    display:       'flex',
    flexDirection: 'column',
    gap:           '6px',
  },
  label: {
    fontSize:   '13px',
    fontWeight: 'bold',
    color:      '#444',
  },
  input: {
    padding:      '10px',
    borderRadius: '6px',
    border:       '1px solid #ddd',
    fontSize:     '14px',
    outline:      'none',
  },
  button: {
    marginTop:       '1rem',
    padding:         '12px',
    backgroundColor: '#1F3864',
    color:           'white',
    border:          'none',
    borderRadius:    '6px',
    fontSize:        '15px',
    cursor:          'pointer',
    fontWeight:      'bold',
    width:           '100%',
  },
  error: {
    backgroundColor: '#fee',
    color:           '#c00',
    padding:         '10px',
    borderRadius:    '6px',
    fontSize:        '13px',
    marginBottom:    '1rem',
  },
  success: {
    backgroundColor: '#efe',
    color:           '#060',
    padding:         '10px',
    borderRadius:    '6px',
    fontSize:        '13px',
    marginBottom:    '1rem',
  }
};