import { useState, useEffect } from 'react';
import Navbar from '../components/Navbar';
import api from '../lib/api';
import { GlucoseReading } from '../types';

export default function GlucoseLogPage() {
  const [value,       setValue]       = useState('');
  const [type,        setType]        = useState('fasting');
  const [notes,       setNotes]       = useState('');
  const [readings,    setReadings]    = useState<GlucoseReading[]>([]);
  const [loading,     setLoading]     = useState(false);
  const [saved,       setSaved]       = useState(false);
  const [error,       setError]       = useState('');

  const fetchReadings = async () => {
    try {
      const res = await api.get('/glucose/history?days=30');
      setReadings(res.data.readings);
    } catch {}
  };

  useEffect(() => { fetchReadings(); }, []);

  const handleLog = async () => {
    if (!value) return;
    setLoading(true);
    setError('');
    setSaved(false);
    try {
      await api.post('/glucose/log', {
        value_mgdl:   parseFloat(value),
        reading_type: type,
        notes:        notes || null,
      });
      setSaved(true);
      setValue('');
      setNotes('');
      fetchReadings();
      setTimeout(() => setSaved(false), 3000);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to log reading');
    } finally {
      setLoading(false);
    }
  };

  const getColor = (val: number) => {
    if (val < 70)  return '#e74c3c';
    if (val > 180) return '#e74c3c';
    if (val > 140) return '#f39c12';
    return '#27ae60';
  };

  const getZone = (val: number) => {
    if (val < 70)  return 'Low';
    if (val > 180) return 'Very High';
    if (val > 140) return 'High';
    return 'Normal';
  };

  return (
    <div style={{ backgroundColor: '#f0f4f8', minHeight: '100vh' }}>
      <Navbar />
      <div style={styles.container}>

        {/* Log Form */}
        <div style={styles.card}>
          <h2 style={styles.title}>Log Glucose Reading</h2>

          {error && <div style={styles.error}>{error}</div>}
          {saved && <div style={styles.success}>Reading logged successfully!</div>}

          <div style={styles.formRow}>
            <div style={styles.field}>
              <label style={styles.label}>Glucose Value (mg/dL)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 95"
                value={value}
                onChange={e => setValue(e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Reading Type</label>
              <select
                style={styles.input}
                value={type}
                onChange={e => setType(e.target.value)}
              >
                <option value="fasting">Fasting</option>
                <option value="post_meal">Post Meal</option>
                <option value="bedtime">Bedtime</option>
                <option value="random">Random</option>
              </select>
            </div>
          </div>

          <div style={styles.field}>
            <label style={styles.label}>Notes (optional)</label>
            <input
              style={styles.input}
              type="text"
              placeholder="e.g. After lunch - had rice and dal"
              value={notes}
              onChange={e => setNotes(e.target.value)}
            />
          </div>

          <button
            style={styles.button}
            onClick={handleLog}
            disabled={loading || !value}
          >
            {loading ? 'Logging...' : 'Log Reading'}
          </button>
        </div>

        {/* Reading History */}
        <div style={styles.card}>
          <h2 style={styles.title}>Recent Readings (Last 30 Days)</h2>
          {readings.length === 0 ? (
            <p style={{ color: '#999', textAlign: 'center' }}>
              No readings logged yet
            </p>
          ) : (
            <table style={styles.table}>
              <thead>
                <tr>
                  <th style={styles.th}>Value</th>
                  <th style={styles.th}>Zone</th>
                  <th style={styles.th}>Type</th>
                  <th style={styles.th}>Notes</th>
                  <th style={styles.th}>Time</th>
                </tr>
              </thead>
              <tbody>
                {readings.map(r => (
                  <tr key={r.id}>
                    <td style={{ ...styles.td, fontWeight: 'bold',
                      color: getColor(r.value_mgdl) }}>
                      {r.value_mgdl} mg/dL
                    </td>
                    <td style={styles.td}>
                      <span style={{
                        backgroundColor: getColor(r.value_mgdl) + '22',
                        color:           getColor(r.value_mgdl),
                        padding:         '2px 8px',
                        borderRadius:    '10px',
                        fontSize:        '12px',
                        fontWeight:      'bold',
                      }}>
                        {getZone(r.value_mgdl)}
                      </span>
                    </td>
                    <td style={styles.td}>{r.reading_type}</td>
                    <td style={styles.td}>{r.notes || '—'}</td>
                    <td style={styles.td}>
                      {new Date(r.measured_at).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    maxWidth: '900px',
    margin:   '2rem auto',
    padding:  '0 1rem',
    display:  'flex',
    flexDirection: 'column',
    gap:      '1.5rem',
  },
  card: {
    backgroundColor: 'white',
    borderRadius:    '12px',
    padding:         '1.5rem',
    boxShadow:       '0 2px 12px rgba(0,0,0,0.08)',
  },
  title: {
    color:     '#1F3864',
    margin:    '0 0 1rem',
    fontSize:  '20px',
  },
  formRow: {
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
    marginTop:       '0.5rem',
    padding:         '11px',
    backgroundColor: '#1F3864',
    color:           'white',
    border:          'none',
    borderRadius:    '6px',
    fontSize:        '14px',
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
  },
  table: {
    width:          '100%',
    borderCollapse: 'collapse',
    fontSize:       '14px',
  },
  th: {
    textAlign:       'left',
    padding:         '10px',
    backgroundColor: '#f8f9fa',
    color:           '#555',
    fontWeight:      'bold',
    fontSize:        '12px',
    borderBottom:    '1px solid #eee',
  },
  td: {
    padding:      '10px',
    borderBottom: '1px solid #f0f0f0',
    color:        '#333',
  }
};