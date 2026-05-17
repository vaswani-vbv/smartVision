import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '../lib/api';

export default function RegisterPage() {
  const navigate  = useNavigate();
  const [name,     setName]     = useState('');
  const [email,    setEmail]    = useState('');
  const [password, setPassword] = useState('');
  const [error,    setError]    = useState('');
  const [loading,  setLoading]  = useState(false);

  const handleRegister = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await api.post('/auth/register', { name, email, password });
      localStorage.setItem('token', res.data.token);
      navigate('/profile');
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <h1 style={styles.title}>Create Account</h1>
        <p style={styles.subtitle}>Join SmartVision to manage your diabetes</p>

        {error && <div style={styles.error}>{error}</div>}

        <input
          style={styles.input}
          type="text"
          placeholder="Full name"
          value={name}
          onChange={e => setName(e.target.value)}
        />
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
        />
        <button
          style={styles.button}
          onClick={handleRegister}
          disabled={loading}
        >
          {loading ? 'Creating account...' : 'Create Account'}
        </button>

        <p style={styles.loginText}>
          Already have an account?{' '}
          <Link to="/login" style={styles.loginLink}>Login here</Link>
        </p>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    minHeight:      'auto',
    display:        'flex',
    alignItems:     'center',
    justifyContent: 'center',
    backgroundColor:'#f0f4f8',
    padding:        '2rem',
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
    fontSize:   '26px',
  },
  subtitle: {
    textAlign: 'center',
    color:     '#666',
    margin:    0,
    fontSize:  '13px',
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
  loginText: {
    textAlign: 'center',
    fontSize:  '13px',
    color:     '#666',
  },
  loginLink: {
    color:          '#2E75B6',
    textDecoration: 'none',
    fontWeight:     'bold',
  }
};