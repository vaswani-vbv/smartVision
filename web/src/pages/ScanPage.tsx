import { useState, useEffect, useRef } from 'react';
import Navbar from '../components/Navbar';

export default function ScanPage() {
  const [loading, setLoading] = useState(false);
  const [fetchingGlucose, setFetchingGlucose] = useState(true);
  const [error, setError] = useState('');
  const [result, setResult] = useState<any>(null);
  const [lastReading, setLastReading] = useState<any>(null);
  
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [detecting, setDetecting] = useState(false);
  const [detectedFood, setDetectedFood] = useState<string | null>(null);
  const [confidence, setConfidence] = useState<number | null>(null);
  const [quantity, setQuantity] = useState<number>(1);
  const [baseNutrition, setBaseNutrition] = useState<any>(null);

  const [useCamera, setUseCamera] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);

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
    
    // Cleanup video stream on unmount
    return () => stopCamera();
  }, []);

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      streamRef.current = stream;
      setUseCamera(true);
      setImagePreview(null);
      setDetectedFood(null);
      setResult(null);
    } catch (err) {
      console.error("Error accessing camera:", err);
      setError("Could not access laptop camera. Please ensure permissions are granted.");
    }
  };

  // Assign the stream to the video element after it renders
  useEffect(() => {
    if (useCamera && videoRef.current && streamRef.current) {
      videoRef.current.srcObject = streamRef.current;
    }
  }, [useCamera]);

  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }
    setUseCamera(false);
  };

  const capturePhoto = () => {
    if (!videoRef.current) return;
    
    const canvas = document.createElement('canvas');
    canvas.width = videoRef.current.videoWidth;
    canvas.height = videoRef.current.videoHeight;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    ctx.drawImage(videoRef.current, 0, 0, canvas.width, canvas.height);
    
    canvas.toBlob((blob) => {
      if (blob) {
        const file = new File([blob], "capture.jpg", { type: "image/jpeg" });
        const url = URL.createObjectURL(blob);
        setImagePreview(url);
        stopCamera(); // Stop live feed after capturing
        
        processImage(file);
      }
    }, 'image/jpeg');
  };

  const update = (field: string, value: string) =>
    setForm(prev => ({ ...prev, [field]: value }));

  const processImage = async (file: File) => {
    setDetecting(true);
    setError('');
    setDetectedFood(null);
    setResult(null);
    
    const formData = new FormData();
    formData.append('image', file);
    
    try {
      const token = localStorage.getItem('token');
      const response = await fetch('http://127.0.0.1:8000/api/camera/detect', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
        body: formData,
      });
      
      const data = await response.json();
      if (!response.ok || data.error) {
        setError(data.error || 'Failed to detect food or nutrition not found');
        return;
      }
      
      setDetectedFood(data.food);
      setConfidence(data.confidence);
      setBaseNutrition(data.nutrition);
      setQuantity(1);
      
      // Auto-fill form
      setForm(prev => ({
        ...prev,
        carbs_g: data.nutrition.carbs.toString(),
        protein_g: data.nutrition.protein.toString(),
        fat_g: data.nutrition.fat.toString(),
        fiber_g: data.nutrition.fiber.toString(),
      }));
    } catch (err) {
      setError('Cannot connect to server');
    } finally {
      setDetecting(false);
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setImagePreview(URL.createObjectURL(file));
      stopCamera();
      await processImage(file);
    }
  };

  const updateQuantity = (delta: number) => {
    const newQuantity = Math.max(1, quantity + delta);
    setQuantity(newQuantity);
    if (baseNutrition) {
      setForm(prev => ({
        ...prev,
        carbs_g: (baseNutrition.carbs * newQuantity).toFixed(1),
        protein_g: (baseNutrition.protein * newQuantity).toFixed(1),
        fat_g: (baseNutrition.fat * newQuantity).toFixed(1),
        fiber_g: (baseNutrition.fiber * newQuantity).toFixed(1),
      }));
    }
  };

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
          <h2 style={styles.title}>Scan Food</h2>
          <p style={styles.subtitle}>
            Use your laptop camera or upload a picture to automatically identify food and populate nutrition details.
          </p>

          {error && <div style={styles.error}>{error}</div>}

          <div style={{ marginBottom: '1.5rem', padding: '1.5rem', border: '1px dashed #ccc', borderRadius: '12px', textAlign: 'center', backgroundColor: '#fafbfc' }}>
            
            {useCamera ? (
              <div style={{ position: 'relative', width: '100%', maxWidth: '500px', margin: '0 auto', borderRadius: '8px', overflow: 'hidden' }}>
                <video 
                  ref={videoRef} 
                  autoPlay 
                  playsInline 
                  style={{ width: '100%', display: 'block', backgroundColor: '#000' }}
                />
                <button 
                  onClick={capturePhoto} 
                  style={{ ...styles.button, margin: '1rem auto 0', width: 'auto', display: 'block' }}
                >
                  📸 Capture Photo
                </button>
                <button 
                  onClick={stopCamera} 
                  style={{ ...styles.button, backgroundColor: '#7f8c8d', margin: '0.5rem auto 0', width: 'auto', display: 'block' }}
                >
                  Cancel Camera
                </button>
              </div>
            ) : (
              <div>
                {imagePreview && (
                  <div style={{ marginBottom: '1.5rem' }}>
                    <img src={imagePreview} alt="Preview" style={{ maxWidth: '100%', maxHeight: '300px', borderRadius: '8px', objectFit: 'contain' }} />
                  </div>
                )}
                
                <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
                  <button onClick={startCamera} style={{ ...styles.button, width: 'auto', margin: 0 }}>
                    📷 Open Laptop Camera
                  </button>
                  
                  <input 
                    type="file" 
                    accept="image/*" 
                    id="cameraInput" 
                    style={{ display: 'none' }} 
                    onChange={handleImageUpload} 
                  />
                  <label htmlFor="cameraInput" style={{ ...styles.button, backgroundColor: '#7f8c8d', display: 'inline-block', cursor: 'pointer', width: 'auto', margin: 0 }}>
                    📁 Upload Image
                  </label>
                </div>
              </div>
            )}
            
            {detecting && <div style={{ marginTop: '1rem', color: '#666', fontWeight: 'bold' }}>Scanning image with YOLOv8...</div>}
            
            {detectedFood && (
              <div style={{ marginTop: '1.5rem', backgroundColor: '#EAFAF1', padding: '1rem', borderRadius: '8px', border: '1px solid #A9DFBF' }}>
                <h3 style={{ margin: '0 0 0.5rem', color: '#1E8449' }}>Detected: {detectedFood}</h3>
                <p style={{ margin: '0 0 1rem', fontSize: '13px', color: '#555' }}>Confidence: {(confidence! * 100).toFixed(1)}%</p>
                
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '15px' }}>
                  <span style={{ fontWeight: 'bold', fontSize: '14px' }}>Quantity:</span>
                  <button onClick={() => updateQuantity(-1)} style={styles.qtyBtn}>-</button>
                  <span style={{ fontWeight: 'bold', fontSize: '16px', minWidth: '20px', textAlign: 'center' }}>{quantity}</span>
                  <button onClick={() => updateQuantity(1)} style={styles.qtyBtn}>+</button>
                </div>
                <p style={{ margin: '10px 0 0', fontSize: '12px', color: '#666' }}>
                  Base Serving: {baseNutrition?.serving_size}
                </p>
              </div>
            )}
          </div>

          <div style={styles.grid}>
            <div style={styles.field}>
              <label style={styles.label}>Carbohydrates (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="Auto-filled"
                value={form.carbs_g}
                onChange={e => update('carbs_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Protein (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="Auto-filled"
                value={form.protein_g}
                onChange={e => update('protein_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Fat (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="Auto-filled"
                value={form.fat_g}
                onChange={e => update('fat_g', e.target.value)}
              />
            </div>
            <div style={styles.field}>
              <label style={styles.label}>Fiber (g)</label>
              <input
                style={styles.input}
                type="number"
                placeholder="Auto-filled"
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
                </div>
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
                      }} />
                    </div>
                  </div>
                ))}
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
  qtyBtn: {
    width: '32px',
    height: '32px',
    borderRadius: '50%',
    border: 'none',
    backgroundColor: '#1E8449',
    color: 'white',
    fontSize: '18px',
    fontWeight: 'bold',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
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
