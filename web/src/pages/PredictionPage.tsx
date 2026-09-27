import { useState, useEffect } from 'react';
import Navbar from '../components/Navbar';

export default function PredictionPage() {
  const [loading, setLoading] = useState(false);
  const [fetchingGlucose, setFetchingGlucose] = useState(true);
  const [error, setError] = useState('');
  const [result, setResult] = useState<any>(null);
  const [lastReading, setLastReading] = useState<any>(null);
  
  const [isType1, setIsType1] = useState(false);
  const [form, setForm] = useState({
    carbs_g: '',
    protein_g: '',
    fat_g: '',
    fiber_g: '',
    pre_meal_glucose: '',
    insulin_dose: '0',
    post_meal_activity: 'none',
  });

  useEffect(() => {
    const fetchLatestGlucoseAndProfile = async () => {
      setFetchingGlucose(true);
      try {
        const token = localStorage.getItem('token');
        const [gRes, pRes] = await Promise.all([
          fetch('http://127.0.0.1:8000/api/glucose/history?days=7', {
            headers: { Authorization: `Bearer ${token}` },
          }),
          fetch('http://127.0.0.1:8000/api/users/profile', {
            headers: { Authorization: `Bearer ${token}` },
          }),
        ]);

        const gData = await gRes.json();
        if (gData.readings && gData.readings.length > 0) {
          const latest = gData.readings[0];
          setLastReading(latest);
          setForm(prev => ({
            ...prev,
            pre_meal_glucose: latest.value_mgdl.toString(),
          }));
        }

        const pData = await pRes.json();
        if (pData && pData.diabetes_type === 'type1') {
          setIsType1(true);
        }
      } catch (err) {
        console.error('Could not fetch latest glucose or profile');
      } finally {
        setFetchingGlucose(false);
      }
    };
    fetchLatestGlucoseAndProfile();
  }, []);

  const update = (field: string, value: string) =>
    setForm(prev => ({ ...prev, [field]: value }));

  const handlePredict = async () => {
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(
        'http://127.0.0.1:8000/api/predictions/predict',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            carbs_g: parseFloat(form.carbs_g),
            protein_g: parseFloat(form.protein_g),
            fat_g: parseFloat(form.fat_g),
            fiber_g: parseFloat(form.fiber_g) || 0,
            pre_meal_glucose: parseFloat(form.pre_meal_glucose),
            insulin_dose: parseFloat(form.insulin_dose) || 0,
            post_meal_activity: form.post_meal_activity,
          }),
        }
      );
      const data = await response.json();
      if (!response.ok) {
        setError(data.detail || 'Prediction failed');
        return;
      }
      setResult(data);
    } catch (err) {
      setError('Cannot connect to server');
    } finally {
      setLoading(false);
    }
  };

  const getRiskColor = (level: string) => {
    if (level === 'normal') return '#27ae60';
    if (level === 'elevated') return '#f39c12';
    return '#e74c3c';
  };

  const formatTime = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleString('en-IN', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div style={{ backgroundColor: '#f0f4f8', minHeight: '100vh' }}>
      <Navbar />
      <div style={styles.container}>
        <div style={styles.card}>
          <h2 style={styles.title}>Manual Glucose Spike Prediction</h2>
          <p style={styles.subtitle}>
            Enter your meal details manually to predict how your glucose will respond
          </p>

          {error && <div style={styles.error}>{error}</div>}

          {fetchingGlucose ? (
            <div style={styles.infoBanner}>
              Fetching your latest glucose reading...
            </div>
          ) : lastReading ? (
            <div style={styles.successBanner}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <span style={{ fontWeight: 'bold' }}>
                    Pre-meal glucose auto-filled
                  </span>
                  <span style={{ marginLeft: '8px', fontSize: '12px' }}>
                    from your last {lastReading.reading_type} reading
                    ({formatTime(lastReading.measured_at)})
                  </span>
                </div>
                <span style={{ fontWeight: 'bold', fontSize: '16px' }}>
                  {lastReading.value_mgdl} mg/dL
                </span>
              </div>
            </div>
          ) : (
            <div style={styles.warnBanner}>
              No recent glucose readings found. Enter your current glucose
              manually or log a reading first.
            </div>
          )}

          <div style={styles.grid}>
            <div style={styles.field}>
              <label style={styles.label}>Carbohydrates (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 60"
                value={form.carbs_g}
                onChange={e => update('carbs_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Protein (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 20"
                value={form.protein_g}
                onChange={e => update('protein_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Fat (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 10"
                value={form.fat_g}
                onChange={e => update('fat_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Fiber (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="e.g. 3"
                value={form.fiber_g}
                onChange={e => update('fiber_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>
                Pre-meal Glucose (mg/dL)
                {lastReading && (
                  <span style={{ marginLeft: '8px', fontSize: '11px', color: '#27ae60', fontWeight: 'normal' }}>
                    auto-filled
                  </span>
                )}
              </label>
              <input
                style={{
                  ...styles.input,
                  borderColor: lastReading ? '#27ae60' : '#ddd',
                  backgroundColor: lastReading ? '#f0fff4' : 'white',
                }}
                type="number"
                placeholder="e.g. 110"
                value={form.pre_meal_glucose}
                onChange={e => update('pre_meal_glucose', e.target.value)}
              />
              {lastReading && (
                <span style={{ fontSize: '11px', color: '#888', marginTop: '2px' }}>
                  You can manually override this value
                </span>
              )}
            </div>

            <div style={styles.field}>
              <label style={styles.label}>
                Bolus Insulin Dose (Units)
                {isType1 && (
                  <span style={{ marginLeft: '8px', fontSize: '11px', color: '#2980b9', fontWeight: 'normal' }}>
                    Type 1 Diabetic
                  </span>
                )}
              </label>
              <input
                style={styles.input}
                type="number"
                placeholder="0"
                value={form.insulin_dose}
                onChange={e => update('insulin_dose', e.target.value)}
              />
            </div>

            <div style={styles.field}>
              <label style={styles.label}>Post-Meal Activity</label>
              <select
                style={styles.input}
                value={form.post_meal_activity}
                onChange={e => update('post_meal_activity', e.target.value)}
              >
                <option value="none">Rest / None (0 mg/dL)</option>
                <option value="light_walk">15m Light Walk (-15 mg/dL)</option>
                <option value="30m_exercise">30m Exercise (-25 mg/dL)</option>
                <option value="45m_workout">45m Workout (-35 mg/dL)</option>
              </select>
            </div>
          </div>

          <button
            style={styles.button}
            onClick={handlePredict}
            disabled={loading || !form.carbs_g || !form.pre_meal_glucose}
          >
            {loading ? 'Predicting...' : 'Predict Glucose Spike'}
          </button>
        </div>

        {result && (
          <div>
            <div style={styles.card}>
              <h2 style={styles.title}>Prediction Result</h2>
              <div style={styles.resultGrid}>
                <div style={styles.metricCard}>
                  <div style={styles.metricLabel}>Predicted Spike</div>
                  <div style={{ ...styles.metricValue, color: getRiskColor(result.risk_level) }}>
                    +{result.predicted_spike} mg/dL
                  </div>
                </div>
                <div style={styles.metricCard}>
                  <div style={styles.metricLabel}>Post-meal Glucose</div>
                  <div style={{ ...styles.metricValue, color: getRiskColor(result.risk_level) }}>
                    {result.predicted_post_meal} mg/dL
                  </div>
                </div>
                <div style={styles.metricCard}>
                  <div style={styles.metricLabel}>Pre-meal Glucose</div>
                  <div style={styles.metricValue}>{result.pre_meal_glucose} mg/dL</div>
                </div>
                <div style={styles.metricCard}>
                  <div style={styles.metricLabel}>Total Calories</div>
                  <div style={styles.metricValue}>{result.calories} kcal</div>
                </div>
              </div>

              <div style={{
                marginTop: '1rem',
                padding: '12px 16px',
                borderRadius: '8px',
                backgroundColor: getRiskColor(result.risk_level) + '18',
                border: `1px solid ${getRiskColor(result.risk_level)}`,
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
              }}>
                <div style={{
                  width: '12px',
                  height: '12px',
                  borderRadius: '50%',
                  backgroundColor: getRiskColor(result.risk_level),
                  flexShrink: 0,
                }} />
                <div>
                  <span style={{ fontWeight: 'bold', color: getRiskColor(result.risk_level), textTransform: 'capitalize' }}>
                    {result.risk_level} risk
                  </span>
                  <span style={{ color: '#555', fontSize: '13px', marginLeft: '8px' }}>
                    {result.risk_level === 'normal' && 'Post-meal glucose is within normal range'}
                    {result.risk_level === 'elevated' && 'Post-meal glucose is elevated — consider a short walk'}
                    {result.risk_level === 'high' && 'Post-meal glucose will be high — consider reducing portion size'}
                  </span>
                </div>
              </div>

              <div style={{
                marginTop: '1rem',
                padding: '10px 14px',
                backgroundColor: '#EBF5FB',
                borderRadius: '6px',
                fontSize: '13px',
                color: '#1A5276',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}>
                <span>
                  After eating, measure your actual glucose and log it to improve future predictions.
                </span>
                <span
                  onClick={() => window.location.href = '/glucose'}
                  style={{
                    color: '#2E75B6',
                    fontWeight: 'bold',
                    fontSize: '12px',
                    textDecoration: 'none',
                    whiteSpace: 'nowrap',
                    marginLeft: '12px',
                    cursor: 'pointer',
                  }}
                >
                  Log Reading
                </span>
              </div>
            </div>

            {result.explanation && (
              <div style={{ ...styles.card, marginTop: '1.5rem' }}>
                <h2 style={styles.title}>Why this prediction?</h2>
                <p style={{ color: '#555', fontSize: '14px', marginBottom: '1.5rem' }}>
                  {result.explanation.summary}
                </p>

                {result.explanation.top_factors.map((factor: any, i: number) => (
                  <div key={i} style={{ marginBottom: '14px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                      <span style={{ fontSize: '13px', fontWeight: 'bold', color: '#333' }}>
                        {factor.label}
                      </span>
                      <span style={{ fontSize: '13px', fontWeight: 'bold', color: factor.shap_value > 0 ? '#e74c3c' : '#27ae60' }}>
                        {factor.shap_value > 0 ? '+' : ''}{factor.shap_value} mg/dL
                      </span>
                    </div>
                    <div style={{ height: '10px', backgroundColor: '#f0f0f0', borderRadius: '5px', overflow: 'hidden' }}>
                      <div style={{
                        height: '100%',
                        width: `${Math.min(Math.abs(factor.shap_value) / Math.abs(result.explanation.top_factors[0].shap_value) * 100, 100)}%`,
                        backgroundColor: factor.shap_value > 0 ? '#e74c3c' : '#27ae60',
                        borderRadius: '5px',
                        transition: 'width 0.5s ease',
                      }} />
                    </div>
                    <div style={{ fontSize: '12px', color: '#777', marginTop: '3px' }}>
                      {factor.impact_text}
                    </div>
                  </div>
                ))}

                <div style={{
                  marginTop: '1rem',
                  padding: '10px 14px',
                  backgroundColor: '#f8f9fa',
                  borderRadius: '6px',
                  fontSize: '12px',
                  color: '#666',
                }}>
                  Base value (average prediction): {result.explanation.base_value} mg/dL.
                  Each factor shows how much it pushes the prediction above or below this baseline.
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    maxWidth: '800px',
    margin: '2rem auto',
    padding: '0 1rem',
    display: 'flex',
    flexDirection: 'column',
    gap: '1.5rem',
  },
  card: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '1.5rem',
    boxShadow: '0 2px 12px rgba(0,0,0,0.08)',
  },
  title: {
    color: '#1F3864',
    margin: '0 0 0.5rem',
    fontSize: '20px',
  },
  subtitle: {
    color: '#666',
    fontSize: '13px',
    margin: '0 0 1rem',
  },
  infoBanner: {
    backgroundColor: '#EBF5FB',
    color: '#1A5276',
    padding: '10px 14px',
    borderRadius: '6px',
    fontSize: '13px',
    marginBottom: '1rem',
  },
  successBanner: {
    backgroundColor: '#EAFAF1',
    color: '#1E8449',
    padding: '10px 14px',
    borderRadius: '6px',
    fontSize: '13px',
    marginBottom: '1rem',
    border: '1px solid #A9DFBF',
  },
  warnBanner: {
    backgroundColor: '#FEF9E7',
    color: '#B7770D',
    padding: '10px 14px',
    borderRadius: '6px',
    fontSize: '13px',
    marginBottom: '1rem',
    border: '1px solid #F9E79F',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '1rem',
    marginBottom: '1rem',
  },
  field: {
    display: 'flex',
    flexDirection: 'column',
    gap: '4px',
  },
  label: {
    fontSize: '13px',
    fontWeight: 'bold',
    color: '#444',
  },
  input: {
    padding: '10px',
    borderRadius: '6px',
    border: '1px solid #ddd',
    fontSize: '14px',
    outline: 'none',
  },
  button: {
    marginTop: '0.5rem',
    padding: '12px',
    backgroundColor: '#1F3864',
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    fontSize: '15px',
    cursor: 'pointer',
    fontWeight: 'bold',
    width: '100%',
  },
  error: {
    backgroundColor: '#fee',
    color: '#c00',
    padding: '10px',
    borderRadius: '6px',
    fontSize: '13px',
    marginBottom: '1rem',
  },
  resultGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '1rem',
    marginBottom: '1rem',
  },
  metricCard: {
    backgroundColor: '#f8f9fa',
    borderRadius: '8px',
    padding: '1rem',
    textAlign: 'center',
  },
  metricLabel: {
    fontSize: '12px',
    color: '#666',
    marginBottom: '6px',
  },
  metricValue: {
    fontSize: '22px',
    fontWeight: 'bold',
    color: '#1F3864',
  },
};