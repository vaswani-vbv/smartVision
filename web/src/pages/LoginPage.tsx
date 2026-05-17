import { useState } from 'react';
import { Link } from 'react-router-dom';

export default function LoginPage() {
  const [email,    setEmail]    = useState('');
  const [password, setPassword] = useState('');
  const [error,    setError]    = useState('');
  const [loading,  setLoading]  = useState(false);

  const handleLogin = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await fetch('http://localhost:8000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });

      const data = await response.json();
      console.log('Response status:', response.status);
      console.log('Response data:', data);

      if (response.ok && data.token) {
        localStorage.setItem('token', data.token);
        console.log('Token stored!');
        window.location.href = '/dashboard';
      } else {
        setError(data.detail || 'Login failed');
      }
    } catch (err) {
      console.error('Fetch error:', err);
      setError('Cannot connect to server');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>SmartVision</h1>
        <p style={styles.subtitle}>Diabetes Management Platform</p>

        {error && <div style={styles.error}>{error}</div>}

        <input
          style={styles.input}
          type="email"
          placeholder="Email address"
          value={email}
          onChange={e => setEmail(e.target.value)}
        />
        <input
          style={styles.input}
          type="password"
          placeholder="Password"
          value={password}
          onChange={e => setPassword(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleLogin()}
        />
        <button
          style={styles.button}
          onClick={handleLogin}
          disabled={loading}
        >
          {loading ? 'Logging in...' : 'Login'}
        </button>

        <p style={styles.registerText}>
          Don't have an account?{' '}
          <Link to="/register" style={styles.registerLink}>Register here</Link>
        </p>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    minHeight:      '100vh',
    display:        'flex',
    alignItems:     'center',
    justifyContent: 'center',
    backgroundColor:'#f0f4f8',
  },
  card: {
    backgroundColor: 'white',
    padding:         '2.5rem',
    borderRadius:    '12px',
    boxShadow:       '0 4px 20px rgba(0,0,0,0.1)',
    width:           '100%',
    maxWidth:        '400px',
    display:         'flex',
    flexDirection:   'column',
    gap:             '1rem',
  },
  title: {
    textAlign:  'center',
    color:      '#1F3864',
    margin:     0,
    fontSize:   '28px',
  },
  subtitle: {
    textAlign: 'center',
    color:     '#666',
    margin:    0,
    fontSize:  '14px',
  },
  input: {
    padding:      '12px',
    borderRadius: '6px',
    border:       '1px solid #ddd',
    fontSize:     '14px',
    outline:      'none',
  },
  button: {
    padding:         '12px',
    backgroundColor: '#1F3864',
    color:           'white',
    border:          'none',
    borderRadius:    '6px',
    fontSize:        '15px',
    cursor:          'pointer',
    fontWeight:      'bold',
  },
  error: {
    backgroundColor: '#fee',
    color:           '#c00',
    padding:         '10px',
    borderRadius:    '6px',
    fontSize:        '13px',
  },
  registerText: {
    textAlign: 'center',
    fontSize:  '13px',
    color:     '#666',
  },
  registerLink: {
    color:          '#2E75B6',
    textDecoration: 'none',
    fontWeight:     'bold',
  }
};