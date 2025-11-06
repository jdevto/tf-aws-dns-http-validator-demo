function StatusDisplay({ status, requestId }) {
  const getStatusIcon = (status) => {
    switch (status) {
      case 'ok':
        return '✅'
      case 'warn':
        return '⚠️'
      case 'fail':
        return '❌'
      default:
        return '⏳'
    }
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'ok':
        return '#28a745'
      case 'warn':
        return '#ffc107'
      case 'fail':
        return '#dc3545'
      default:
        return '#6c757d'
    }
  }

  const formatStepName = (step) => {
    return step
      .replace(/([A-Z])/g, ' $1')
      .replace(/^./, str => str.toUpperCase())
      .trim()
  }

  const formatTimestamp = (ts) => {
    if (!ts) return 'N/A'
    try {
      const date = new Date(ts)
      return date.toLocaleString()
    } catch {
      return ts
    }
  }

  // Handle null/undefined status
  if (!status) {
    return (
      <div className="status-display">
        <h2>Validation Status</h2>
        <div className="request-id">Request ID: <code>{requestId}</code></div>
        <div className="loading">Waiting for validation to start...</div>
      </div>
    )
  }

  return (
    <div className="status-display">
      <h2>Validation Status</h2>
      <div className="request-id">Request ID: <code>{requestId}</code></div>

      {status?.summary && (
        <div className="summary">
          <h3>Summary</h3>
          <div className="summary-item">
            <span className="summary-label">Target:</span>
            <span className="summary-value">{status.summary.target}</span>
          </div>
          <div className="summary-item">
            <span className="summary-label">Overall Status:</span>
            <span
              className="summary-value"
              style={{ color: getStatusColor(status.summary.overallStatus) }}
            >
              {getStatusIcon(status.summary.overallStatus)} {status.summary.overallStatus?.toUpperCase()}
            </span>
          </div>
          {status.summary.startedAt && (
            <div className="summary-item">
              <span className="summary-label">Started:</span>
              <span className="summary-value">{formatTimestamp(status.summary.startedAt)}</span>
            </div>
          )}
          {status.summary.finishedAt && (
            <div className="summary-item">
              <span className="summary-label">Finished:</span>
              <span className="summary-value">{formatTimestamp(status.summary.finishedAt)}</span>
            </div>
          )}
        </div>
      )}

      {status?.steps && status.steps.length > 0 && (
        <div className="steps">
          <h3>Steps</h3>
          <div className="steps-list">
            {status.steps.map((step, index) => (
              <div key={index} className="step-item">
                <div className="step-header">
                  <span className="step-icon">{getStatusIcon(step.status)}</span>
                  <span className="step-name">{formatStepName(step.step)}</span>
                  <span
                    className="step-status"
                    style={{ color: getStatusColor(step.status) }}
                  >
                    {step.status?.toUpperCase()}
                  </span>
                </div>
                {step.reason && (
                  <div className="step-reason">{step.reason}</div>
                )}
                {step.timings && (
                  <div className="step-timings">
                    {Object.entries(step.timings).map(([key, value]) => (
                      <span key={key} className="timing">
                        {key}: {value}ms
                      </span>
                    ))}
                  </div>
                )}
                {step.ts && (
                  <div className="step-timestamp">Time: {formatTimestamp(step.ts)}</div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {!status?.summary && (!status?.steps || status.steps.length === 0) && (
        <div className="loading">Waiting for validation to start...</div>
      )}
    </div>
  )
}

export default StatusDisplay
