import { useState, useEffect } from 'react';
import Navbar from '../components/Navbar';
import api from '../lib/api';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  ReferenceArea
} from 'recharts';

export default function DashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsRes, historyRes] = await Promise.all([
          api.get('/glucose/stats?days=30'),
          api.get('/glucose/history?days=7')
        ]);
        
        setStats(statsRes.data);
        
        // Format history for chart (oldest to newest)
        const formattedHistory = [...historyRes.data.readings]
          .reverse()
          .map((r: any) => ({
            time: new Date(r.measured_at).toLocaleDateString('en-IN', { weekday: 'short', hour: '2-digit', minute:'2-digit' }),
            value: r.value_mgdl,
            type: r.reading_type
          }));
          
        setHistory(formattedHistory);
      } catch (err: any) {
        setError('Failed to load dashboard data');
      } finally {
        setLoading(false);
      }
    };
    
    fetchData();
  }, []);

  if (loading) {
    return (
      <div style={{ backgroundColor: '#f0f4f8', minHeight: '100vh' }}>
        <Navbar />
        <div style={{ textAlign: 'center', marginTop: '4rem', color: '#666' }}>Loading your dashboard...</div>
      </div>
    );
  }

  return (
    <div style={{ backgroundColor: '#f0f4f8', minHeight: '100vh' }}>
      <Navbar />
      <div style={styles.container}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '0.5rem' }}>
          <div>
            <h1 style={styles.title}>Your Dashboard</h1>
            <p style={styles.subtitle}>Overview of your glucose levels over the last 30 days</p>
          </div>
        </div>

        {error && <div style={styles.error}>{error}</div>}

        {!stats || stats.message ? (
          <div style={styles.card}>
            <p style={{ color: '#666', textAlign: 'center' }}>No glucose readings logged yet. Log some readings to see your stats!</p>
          </div>
        ) : (
          <>
            {/* Stats Cards */}
            <div style={styles.statsGrid}>
              <div style={styles.statCard}>
                <div style={styles.statLabel}>Average Glucose</div>
                <div style={{ ...styles.statValue, color: '#2E86C1' }}>
                  {stats.average_mgdl} <span style={styles.statUnit}>mg/dL</span>
                </div>
              </div>
              
              <div style={styles.statCard}>
                <div style={styles.statLabel}>Time In Range (70-140)</div>
                <div style={{ ...styles.statValue, color: stats.in_range_pct >= 70 ? '#27ae60' : '#f39c12' }}>
                  {stats.in_range_pct}%
                </div>
              </div>
              
              <div style={styles.statCard}>
                <div style={styles.statLabel}>Highest Reading</div>
                <div style={{ ...styles.statValue, color: '#e74c3c' }}>
                  {stats.highest_mgdl} <span style={styles.statUnit}>mg/dL</span>
                </div>
              </div>
              
              <div style={styles.statCard}>
                <div style={styles.statLabel}>Lowest Reading</div>
                <div style={{ ...styles.statValue, color: stats.lowest_mgdl < 70 ? '#e74c3c' : '#27ae60' }}>
                  {stats.lowest_mgdl} <span style={styles.statUnit}>mg/dL</span>
                </div>
              </div>
            </div>

            {/* Zone Breakdown */}
            <div style={styles.card}>
              <h2 style={styles.cardTitle}>Zone Breakdown (30 Days)</h2>
              <div style={{ display: 'flex', height: '24px', borderRadius: '12px', overflow: 'hidden', marginTop: '1rem' }}>
                {stats.below_range > 0 && (
                  <div style={{ width: `${(stats.below_range / stats.total_readings) * 100}%`, backgroundColor: '#e74c3c' }} title={`Low: ${stats.below_range}`} />
                )}
                {stats.in_range > 0 && (
                  <div style={{ width: `${(stats.in_range / stats.total_readings) * 100}%`, backgroundColor: '#27ae60' }} title={`Target: ${stats.in_range}`} />
                )}
                {stats.above_range > 0 && (
                  <div style={{ width: `${(stats.above_range / stats.total_readings) * 100}%`, backgroundColor: '#f39c12' }} title={`High: ${stats.above_range}`} />
                )}
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '8px', fontSize: '12px', color: '#666' }}>
                <span><span style={{ color: '#e74c3c', fontWeight: 'bold' }}>Low</span> ({stats.below_range})</span>
                <span><span style={{ color: '#27ae60', fontWeight: 'bold' }}>Target</span> ({stats.in_range})</span>
                <span><span style={{ color: '#f39c12', fontWeight: 'bold' }}>High</span> ({stats.above_range})</span>
              </div>
            </div>

            {/* Chart */}
            {history.length > 0 && (
              <div style={styles.card}>
                <h2 style={styles.cardTitle}>Recent Trends (Last 7 Days)</h2>
                <div style={{ height: '300px', width: '100%', marginTop: '1.5rem' }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={history} margin={{ top: 5, right: 20, bottom: 5, left: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#eee" />
                      <XAxis dataKey="time" tick={{ fontSize: 11, fill: '#888' }} tickMargin={10} />
                      <YAxis domain={['auto', 'auto']} tick={{ fontSize: 11, fill: '#888' }} axisLine={false} tickLine={false} />
                      <Tooltip 
                        contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                        labelStyle={{ color: '#666', marginBottom: '4px', fontSize: '12px' }}
                      />
                      <ReferenceArea y1={70} y2={140} fill="#27ae60" fillOpacity={0.1} />
                      <Line 
                        type="monotone" 
                        dataKey="value" 
                        name="Glucose (mg/dL)"
                        stroke="#2E86C1" 
                        strokeWidth={3}
                        dot={{ r: 4, fill: '#2E86C1', strokeWidth: 2, stroke: '#fff' }}
                        activeDot={{ r: 6 }} 
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    maxWidth: '1000px',
    margin: '2rem auto',
    padding: '0 1rem',
    display: 'flex',
    flexDirection: 'column',
    gap: '1.5rem',
  },
  title: {
    color: '#1F3864',
    margin: '0 0 0.5rem',
    fontSize: '26px',
  },
  subtitle: {
    color: '#666',
    fontSize: '14px',
    margin: 0,
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '1rem',
  },
  statCard: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '1.5rem',
    boxShadow: '0 2px 12px rgba(0,0,0,0.05)',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
  },
  statLabel: {
    fontSize: '13px',
    color: '#666',
    fontWeight: 'bold',
    textTransform: 'uppercase',
    letterSpacing: '0.5px',
    marginBottom: '8px',
  },
  statValue: {
    fontSize: '28px',
    fontWeight: '900',
  },
  statUnit: {
    fontSize: '14px',
    fontWeight: 'normal',
    color: '#888',
    marginLeft: '2px',
  },
  card: {
    backgroundColor: 'white',
    borderRadius: '12px',
    padding: '1.5rem',
    boxShadow: '0 2px 12px rgba(0,0,0,0.05)',
  },
  cardTitle: {
    color: '#1F3864',
    margin: 0,
    fontSize: '18px',
  },
  error: {
    backgroundColor: '#fee',
    color: '#c00',
    padding: '12px',
    borderRadius: '8px',
    fontSize: '14px',
  },
};