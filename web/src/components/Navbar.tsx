import { Link, useNavigate, useLocation } from 'react-router-dom';

export default function Navbar() {
  const navigate = useNavigate();
  const location = useLocation();

  const userEmail = localStorage.getItem('userEmail') || '';
  const isAdmin = userEmail.toLowerCase() === 'admin@smartvision.com' || location.pathname.startsWith('/admin');

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('userEmail');
    navigate('/login');
  };

  return (
    <nav style={styles.nav}>
      <div style={styles.brand}>
        SmartVision {isAdmin && <span style={styles.adminTag}>Admin Portal</span>}
      </div>
      <div style={styles.links}>
        {!isAdmin && (
          <>
            <Link to="/dashboard" style={styles.link}>Dashboard</Link>
            <Link to="/profile"   style={styles.link}>Profile</Link>
            <Link to="/glucose"   style={styles.link}>Log Glucose</Link>
            <Link to="/predict"   style={styles.link}>Manual Predict</Link>
            <Link to="/scan"      style={styles.link}>Scan Food</Link>
          </>
        )}
        {isAdmin && (
          <Link to="/admin/kyc" style={styles.adminBadge}>🛡️ Admin KYC Portal</Link>
        )}
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
    backgroundColor: '#0f172a',
    borderBottom:    '1px solid #1e293b',
    color:           'white',
  },
  brand: {
    fontSize:   '20px',
    fontWeight: 'bold',
    color:      '#38bdf8',
    display:    'flex',
    alignItems: 'center',
    gap:        '10px',
  },
  adminTag: {
    backgroundColor: '#38bdf8',
    color: '#0f172a',
    padding: '2px 8px',
    borderRadius: '6px',
    fontSize: '12px',
    fontWeight: 'bold',
  },

  links: {
    display: 'flex',
    gap:     '1.2rem',
    alignItems: 'center',
  },
  link: {
    color:          '#cbd5e1',
    textDecoration: 'none',
    fontSize:       '14px',
  },
  adminBadge: {
    backgroundColor: '#38bdf820',
    border: '1px solid #38bdf8',
    color: '#38bdf8',
    textDecoration: 'none',
    fontSize: '13px',
    padding: '6px 14px',
    borderRadius: '12px',
    fontWeight: '600',
  },
  logout: {
    backgroundColor: 'transparent',
    border:          '1px solid #64748b',
    color:           '#cbd5e1',
    padding:         '6px 14px',
    borderRadius:    '6px',
    cursor:          'pointer',
    fontSize:        '14px',
  }
};
