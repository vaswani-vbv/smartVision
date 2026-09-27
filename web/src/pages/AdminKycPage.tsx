import React, { useEffect, useState } from 'react';
import api from '../lib/api';
import Navbar from '../components/Navbar';

interface VerificationItem {
  user_id: string;
  email: string;
  name: string;
  profile_picture_url: string | null;
  status: 'verified' | 'pending' | 'rejected' | 'unverified';
  id_type: string | null;
  id_number: string | null;
  document_image_url: string | null;
  rejection_reason: string | null;
  submitted_at: string | null;
}

export default function AdminKycPage() {
  const [items, setItems] = useState<VerificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  
  // Rejection Modal state
  const [rejectingItem, setRejectingItem] = useState<VerificationItem | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // Document Lightbox state
  const [previewImage, setPreviewImage] = useState<{ url: string; title: string } | null>(null);

  const fetchVerifications = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/users/admin/verifications');
      setItems(response.data);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to load user verifications');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVerifications();
  }, []);

  const handleUpdateStatus = async (userEmail: string, newStatus: string, reason?: string) => {
    setActionLoading(userEmail);
    try {
      await api.post('/users/admin/verify-kyc', {
        user_email: userEmail,
        status: newStatus,
        rejection_reason: reason,
      });
      setRejectingItem(null);
      setRejectionReason('');
      fetchVerifications();
    } catch (err: any) {
      alert(err.response?.data?.detail || 'Failed to update user status');
    } finally {
      setActionLoading(null);
    }
  };

  // Delete Patient state
  const [deletingItem, setDeletingItem] = useState<VerificationItem | null>(null);

  const handleDeletePatient = async (targetItem: VerificationItem) => {
    const identifier = targetItem.user_id || targetItem.email;
    setActionLoading(targetItem.user_id);
    try {
      await api.delete(`/users/admin/patient/${identifier}`);
      setDeletingItem(null);
      fetchVerifications();
    } catch (err: any) {
      console.error('Delete patient error:', err);
      const detail = err.response?.data?.detail || err.message || 'Failed to delete patient';
      alert(`Error deleting patient: ${detail}`);
    } finally {
      setActionLoading(null);
    }
  };


  // Stats calculation
  const totalCount = items.length;
  const pendingCount = items.filter((i) => i.status === 'pending').length;
  const verifiedCount = items.filter((i) => i.status === 'verified').length;
  const rejectedCount = items.filter((i) => i.status === 'rejected').length;

  const filteredItems = items.filter((item) => {
    const matchesSearch =
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.email.toLowerCase().includes(search.toLowerCase()) ||
      (item.id_number && item.id_number.toLowerCase().includes(search.toLowerCase()));

    if (!matchesSearch) return false;
    if (statusFilter === 'all') return true;
    return item.status === statusFilter;
  });

  const getFullUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `http://127.0.0.1:8000${url}`;
  };


  return (
    <div style={styles.page}>
      <Navbar />

      <div style={styles.container}>
        {/* Header Title */}
        <div style={styles.header}>
          <div>
            <h1 style={styles.title}>Hospital Admin — Identity & KYC Portal</h1>
            <p style={styles.subtitle}>
              Review patient government identity documents (Aadhaar, PAN, Passport, Voter ID) and manage verification status.
            </p>
          </div>
          <button onClick={fetchVerifications} style={styles.refreshBtn} disabled={loading}>
            🔄 {loading ? 'Refreshing...' : 'Refresh List'}
          </button>
        </div>

        {/* Stats Cards */}
        <div style={styles.statsGrid}>
          <div style={{ ...styles.statCard, borderColor: '#3b82f6' }}>
            <div style={styles.statNumber}>{totalCount}</div>
            <div style={styles.statLabel}>Total Patients</div>
          </div>
          <div style={{ ...styles.statCard, borderColor: '#eab308' }}>
            <div style={{ ...styles.statNumber, color: '#eab308' }}>{pendingCount}</div>
            <div style={styles.statLabel}>Pending Review</div>
          </div>
          <div style={{ ...styles.statCard, borderColor: '#22c55e' }}>
            <div style={{ ...styles.statNumber, color: '#22c55e' }}>{verifiedCount}</div>
            <div style={styles.statLabel}>Verified Patients</div>
          </div>
          <div style={{ ...styles.statCard, borderColor: '#ef4444' }}>
            <div style={{ ...styles.statNumber, color: '#ef4444' }}>{rejectedCount}</div>
            <div style={styles.statLabel}>Rejected IDs</div>
          </div>
        </div>

        {/* Controls Bar: Search & Filter Tabs */}
        <div style={styles.controlsBar}>
          <input
            type="text"
            placeholder="🔍 Search by patient name, email, or ID number..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={styles.searchInput}
          />
          <div style={styles.tabContainer}>
            {['all', 'pending', 'verified', 'rejected', 'unverified'].map((tab) => (
              <button
                key={tab}
                onClick={() => setStatusFilter(tab)}
                style={{
                  ...styles.tabBtn,
                  ...(statusFilter === tab ? styles.activeTabBtn : {}),
                }}
              >
                {tab.toUpperCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Error message */}
        {error && <div style={styles.errorBanner}>⚠️ {error}</div>}

        {/* Patient Table */}
        {loading ? (
          <div style={styles.loadingState}>Loading patient records...</div>
        ) : filteredItems.length === 0 ? (
          <div style={styles.emptyState}>No patient records found matching your filters.</div>
        ) : (
          <div style={styles.tableWrapper}>
            <table style={styles.table}>
              <thead>
                <tr style={styles.tableHeader}>
                  <th style={styles.th}>Patient</th>
                  <th style={styles.th}>Submitted ID</th>
                  <th style={styles.th}>ID Number</th>
                  <th style={styles.th}>Document Photo</th>
                  <th style={styles.th}>Status</th>
                  <th style={styles.th}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredItems.map((item) => (
                  <tr key={item.user_id} style={styles.tableRow}>
                    {/* Patient Name & Email */}
                    <td style={styles.td}>
                      <div style={styles.patientInfo}>
                        {item.profile_picture_url ? (
                          <img
                            src={getFullUrl(item.profile_picture_url)}
                            alt={item.name}
                            style={styles.avatarImg}
                          />
                        ) : (
                          <div style={styles.avatarPlaceholder}>
                            {item.name ? item.name.charAt(0).toUpperCase() : '?'}
                          </div>
                        )}
                        <div>
                          <div style={styles.patientName}>{item.name}</div>
                          <div style={styles.patientEmail}>{item.email}</div>
                        </div>
                      </div>
                    </td>

                    {/* ID Type */}
                    <td style={styles.td}>
                      {item.id_type ? (
                        <span style={styles.idTypeTag}>{item.id_type.toUpperCase()}</span>
                      ) : (
                        <span style={{ color: '#94a3b8' }}>None</span>
                      )}
                    </td>

                    {/* ID Number */}
                    <td style={styles.td}>
                      {item.id_number ? (
                        <span style={styles.idNumber}>{item.id_number}</span>
                      ) : (
                        <span style={{ color: '#94a3b8' }}>—</span>
                      )}
                    </td>

                    {/* Document Image */}
                    <td style={styles.td}>
                      {item.document_image_url ? (
                        <button
                          onClick={() =>
                            setPreviewImage({
                              url: getFullUrl(item.document_image_url),
                              title: `${item.name}'s ${item.id_type?.toUpperCase() || 'Document'}`,
                            })
                          }
                          style={styles.viewDocBtn}
                        >
                          👁️ View Document
                        </button>
                      ) : (
                        <span style={{ color: '#94a3b8', fontSize: '13px' }}>No photo attached</span>
                      )}
                    </td>

                    {/* Status Badge */}
                    <td style={styles.td}>
                      <StatusBadge status={item.status} reason={item.rejection_reason} />
                    </td>

                    {/* Action Buttons */}
                    <td style={styles.td}>
                      <div style={styles.actionGroup}>
                        {item.status !== 'verified' && (
                          <button
                            onClick={() => handleUpdateStatus(item.email, 'verified')}
                            disabled={actionLoading === item.email}
                            style={styles.approveBtn}
                          >
                            ✅ Approve
                          </button>
                        )}
                        {item.status !== 'rejected' && item.status !== 'unverified' && (
                          <button
                            onClick={() => setRejectingItem(item)}
                            disabled={actionLoading === item.email}
                            style={styles.rejectBtn}
                          >
                            ❌ Reject
                          </button>
                        )}
                        {item.status === 'verified' && (
                          <button
                            onClick={() => handleUpdateStatus(item.email, 'pending')}
                            disabled={actionLoading === item.email}
                            style={styles.resetBtn}
                          >
                            🔄 Reset
                          </button>
                        )}
                        <button
                          onClick={() => setDeletingItem(item)}
                          disabled={actionLoading === item.user_id}
                          style={styles.deleteBtn}
                          title="Remove Patient"
                        >
                          🗑️ Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Rejection Modal */}
      {rejectingItem && (
        <div style={styles.modalOverlay}>
          <div style={styles.modalContent}>
            <h3>Reject Verification — {rejectingItem.name}</h3>
            <p style={{ color: '#64748b', fontSize: '14px', marginBottom: '16px' }}>
              Please specify a reason for rejection (e.g. invalid document number, blurry photo):
            </p>
            <textarea
              rows={3}
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g. Document image is not legible. Please upload a clear photo of your PAN card."
              style={styles.modalTextarea}
            />
            <div style={styles.modalActions}>
              <button onClick={() => setRejectingItem(null)} style={styles.cancelBtn}>
                Cancel
              </button>
              <button
                onClick={() =>
                  handleUpdateStatus(
                    rejectingItem.email,
                    'rejected',
                    rejectionReason || 'Document verification failed.'
                  )
                }
                style={styles.confirmRejectBtn}
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Patient Confirmation Modal */}
      {deletingItem && (
        <div style={styles.modalOverlay}>
          <div style={styles.modalContent}>
            <h3 style={{ color: '#ef4444', margin: '0 0 10px 0' }}>⚠️ Remove Patient Account</h3>
            <p style={{ color: '#f8fafc', fontSize: '14px', marginBottom: '12px' }}>
              Are you sure you want to permanently delete patient <strong>{deletingItem.name}</strong> (<code>{deletingItem.email}</code>)?
            </p>
            <p style={{ color: '#94a3b8', fontSize: '13px', marginBottom: '20px' }}>
              This will permanently delete their account, medical profile, glucose logs, and ID verification records. This action cannot be undone.
            </p>
            <div style={styles.modalActions}>
              <button onClick={() => setDeletingItem(null)} style={styles.cancelBtn}>
                Cancel
              </button>
              <button
                onClick={() => handleDeletePatient(deletingItem)}
                style={styles.confirmDeleteBtn}
              >

                Permanently Delete Patient
              </button>
            </div>
          </div>
        </div>
      )}


      {/* Image Lightbox Modal */}
      {previewImage && (
        <div style={styles.modalOverlay} onClick={() => setPreviewImage(null)}>
          <div style={styles.imageModalContent} onClick={(e) => e.stopPropagation()}>
            <div style={styles.imageModalHeader}>
              <h3 style={{ margin: 0, color: 'white' }}>{previewImage.title}</h3>
              <button onClick={() => setPreviewImage(null)} style={styles.closeBtn}>
                ✕
              </button>
            </div>
            <div style={styles.imageWrapper}>
              <img src={previewImage.url} alt="ID Document" style={styles.previewImg} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Sub-component for Status Badge
function StatusBadge({ status, reason }: { status: string; reason: string | null }) {
  let bg = '#e2e8f0';
  let color = '#475569';
  let label = 'Unverified';

  if (status === 'verified') {
    bg = '#dcfce7';
    color = '#15803d';
    label = '✅ Verified';
  } else if (status === 'pending') {
    bg = '#fef9c3';
    color = '#a16207';
    label = '🕐 Pending';
  } else if (status === 'rejected') {
    bg = '#fee2e2';
    color = '#b91c1c';
    label = '❌ Rejected';
  }

  return (
    <div>
      <span
        style={{
          backgroundColor: bg,
          color: color,
          padding: '4px 10px',
          borderRadius: '12px',
          fontSize: '12px',
          fontWeight: 'bold',
          display: 'inline-block',
        }}
      >
        {label}
      </span>
      {status === 'rejected' && reason && (
        <div style={{ color: '#ef4444', fontSize: '11px', marginTop: '4px', maxWidth: '160px' }}>
          {reason}
        </div>
      )}
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  page: {
    minHeight: '100vh',
    backgroundColor: '#0f172a',
    color: '#f8fafc',
    fontFamily: "'Inter', sans-serif",
  },
  container: {
    maxWidth: '1200px',
    margin: '0 auto',
    padding: '2rem 1.5rem',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '2rem',
  },
  title: {
    fontSize: '26px',
    fontWeight: 'bold',
    margin: '0 0 6px 0',
    background: 'linear-gradient(90deg, #38bdf8, #818cf8)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
  },
  subtitle: {
    fontSize: '14px',
    color: '#94a3b8',
    margin: 0,
  },
  refreshBtn: {
    backgroundColor: '#1e293b',
    border: '1px solid #334155',
    color: '#38bdf8',
    padding: '10px 18px',
    borderRadius: '8px',
    cursor: 'pointer',
    fontWeight: '600',
    fontSize: '14px',
  },
  statsGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
    gap: '1.25rem',
    marginBottom: '2rem',
  },
  statCard: {
    backgroundColor: '#1e293b',
    borderRadius: '12px',
    padding: '1.25rem',
    borderLeft: '5px solid #3b82f6',
    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
  },
  statNumber: {
    fontSize: '28px',
    fontWeight: 'bold',
    color: '#f8fafc',
  },
  statLabel: {
    fontSize: '13px',
    color: '#94a3b8',
    marginTop: '4px',
  },
  controlsBar: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: '1rem',
    marginBottom: '1.5rem',
    flexWrap: 'wrap',
  },
  searchInput: {
    flex: '1',
    minWidth: '280px',
    backgroundColor: '#1e293b',
    border: '1px solid #334155',
    color: 'white',
    padding: '12px 16px',
    borderRadius: '8px',
    fontSize: '14px',
    outline: 'none',
  },
  tabContainer: {
    display: 'flex',
    gap: '6px',
    backgroundColor: '#1e293b',
    padding: '4px',
    borderRadius: '8px',
  },
  tabBtn: {
    backgroundColor: 'transparent',
    border: 'none',
    color: '#94a3b8',
    padding: '8px 14px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
  },
  activeTabBtn: {
    backgroundColor: '#38bdf8',
    color: '#0f172a',
  },
  tableWrapper: {
    backgroundColor: '#1e293b',
    borderRadius: '12px',
    overflow: 'hidden',
    border: '1px solid #334155',
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse',
    textAlign: 'left',
  },
  tableHeader: {
    backgroundColor: '#0f172a',
    borderBottom: '1px solid #334155',
  },
  th: {
    padding: '14px 18px',
    fontSize: '13px',
    fontWeight: '600',
    color: '#94a3b8',
  },
  tableRow: {
    borderBottom: '1px solid #334155',
  },
  td: {
    padding: '14px 18px',
    fontSize: '14px',
  },
  patientInfo: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
  },
  avatarImg: {
    width: '40px',
    height: '40px',
    borderRadius: '50%',
    objectFit: 'cover',
  },
  avatarPlaceholder: {
    width: '40px',
    height: '40px',
    borderRadius: '50%',
    backgroundColor: '#38bdf8',
    color: '#0f172a',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontWeight: 'bold',
  },
  patientName: {
    fontWeight: '600',
    color: '#f8fafc',
  },
  patientEmail: {
    fontSize: '12px',
    color: '#94a3b8',
  },
  idTypeTag: {
    backgroundColor: '#334155',
    color: '#38bdf8',
    padding: '3px 8px',
    borderRadius: '6px',
    fontSize: '11px',
    fontWeight: 'bold',
  },
  idNumber: {
    fontFamily: 'monospace',
    letterSpacing: '0.5px',
    color: '#cbd5e1',
  },
  viewDocBtn: {
    backgroundColor: 'transparent',
    border: '1px solid #38bdf8',
    color: '#38bdf8',
    padding: '6px 12px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
  },
  actionGroup: {
    display: 'flex',
    gap: '6px',
  },
  approveBtn: {
    backgroundColor: '#16a34a',
    border: 'none',
    color: 'white',
    padding: '6px 12px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
  },
  rejectBtn: {
    backgroundColor: '#dc2626',
    border: 'none',
    color: 'white',
    padding: '6px 12px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
  },
  resetBtn: {
    backgroundColor: '#475569',
    border: 'none',
    color: 'white',
    padding: '6px 12px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
  },
  deleteBtn: {
    backgroundColor: '#991b1b20',
    border: '1px solid #991b1b',
    color: '#fca5a5',
    padding: '6px 10px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '600',
  },
  confirmDeleteBtn: {
    backgroundColor: '#991b1b',
    border: 'none',
    color: 'white',
    padding: '8px 16px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontWeight: '600',
  },

  modalOverlay: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.75)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 1000,
    padding: '20px',
  },
  modalContent: {
    backgroundColor: '#1e293b',
    borderRadius: '14px',
    padding: '24px',
    maxWidth: '480px',
    width: '100%',
    border: '1px solid #334155',
  },
  modalTextarea: {
    width: '100%',
    backgroundColor: '#0f172a',
    border: '1px solid #334155',
    color: 'white',
    borderRadius: '8px',
    padding: '12px',
    fontSize: '14px',
    marginBottom: '20px',
    outline: 'none',
  },
  modalActions: {
    display: 'flex',
    justifyContent: 'flex-end',
    gap: '12px',
  },
  cancelBtn: {
    backgroundColor: '#334155',
    border: 'none',
    color: 'white',
    padding: '8px 16px',
    borderRadius: '6px',
    cursor: 'pointer',
  },
  confirmRejectBtn: {
    backgroundColor: '#dc2626',
    border: 'none',
    color: 'white',
    padding: '8px 16px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontWeight: '600',
  },
  imageModalContent: {
    backgroundColor: '#1e293b',
    borderRadius: '14px',
    padding: '20px',
    maxWidth: '700px',
    width: '100%',
    border: '1px solid #334155',
  },
  imageModalHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '16px',
  },
  closeBtn: {
    backgroundColor: 'transparent',
    border: 'none',
    color: '#94a3b8',
    fontSize: '18px',
    cursor: 'pointer',
  },
  imageWrapper: {
    maxHeight: '500px',
    overflow: 'auto',
    borderRadius: '8px',
    backgroundColor: '#0f172a',
    display: 'flex',
    justifyContent: 'center',
  },
  previewImg: {
    maxWidth: '100%',
    maxHeight: '480px',
    objectFit: 'contain',
  },
  loadingState: {
    textAlign: 'center',
    padding: '3rem',
    color: '#94a3b8',
  },
  emptyState: {
    textAlign: 'center',
    padding: '3rem',
    color: '#94a3b8',
    backgroundColor: '#1e293b',
    borderRadius: '12px',
  },
  errorBanner: {
    backgroundColor: '#ef444420',
    border: '1px solid #ef4444',
    color: '#ef4444',
    padding: '12px',
    borderRadius: '8px',
    marginBottom: '1rem',
  },
};
