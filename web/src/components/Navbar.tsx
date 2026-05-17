import { Link, useNavigate } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();

  const logout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  return (
    <nav style={styles.nav}>
      <div style={styles.brand}>SmartVision</div>
      <div style={styles.links}>
        <Link to="/dashboard" style={styles.link}>Dashboard</Link>
        <Link to="/profile"   style={styles.link}>Profile</Link>
        <Link to="/glucose"   style={styles.link}>Log Glucose</Link>
        <Link to="/predict"   style={styles.link}>Predict</Link>
        <button onClick={logout} style={styles.logout}>Logout</button>
      </div>
    </nav>
  );
}

const styles: Record<string, React.CSSProperties> = {
  nav: {
    display:         'flex',
    justifyContent:  'space-between',
    alignItems:      'center',
    padding:         '0 2rem',
    height:          '60px',
    backgroundColor: '#1F3864',
    color:           'white',
  },
  brand: {
    fontSize:   '20px',
    fontWeight: 'bold',
    color:      'white',
  },
  links: {
    display: 'flex',
    gap:     '1.5rem',
    alignItems: 'center',
  },
  link: {
    color:          'white',
    textDecoration: 'none',
    fontSize:       '14px',
  },
  logout: {
    backgroundColor: 'transparent',
    border:          '1px solid white',
    color:           'white',
    padding:         '6px 14px',
    borderRadius:    '4px',
    cursor:          'pointer',
    fontSize:        '14px',
  }
};