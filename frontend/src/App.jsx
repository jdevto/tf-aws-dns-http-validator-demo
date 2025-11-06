import { useState } from 'react'
import './App.css'
import StatusDisplay from './components/StatusDisplay'
import ValidationForm from './components/ValidationForm'
import { usePolling } from './hooks/usePolling'

// Get API endpoint from environment or use placeholder
const API_ENDPOINT = import.meta.env.VITE_API_ENDPOINT || ''

function App() {
  const [requestId, setRequestId] = useState(null)
  const [status, setStatus] = useState(null)
  const [error, setError] = useState(null)

  // Poll for status updates
  usePolling(
    () => {
      if (!requestId || !API_ENDPOINT) {
        return null
      }
      return `${API_ENDPOINT}/status?requestId=${requestId}`
    },
    (data) => {
      if (data) {
        setStatus(data)
        // Stop polling if validation is complete
        if (data?.summary?.overallStatus) {
          return true // Signal to stop polling
        }
      }
      return false
    },
    2000, // 2 second interval
    [requestId] // Restart polling when requestId changes
  )

  const handleSubmit = async (target) => {
    setError(null)
    setStatus(null)

    try {
      const response = await fetch(`${API_ENDPOINT}/check`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ target }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to submit validation request')
      }

      const data = await response.json()
      setRequestId(data.requestId)
    } catch (err) {
      setError(err.message)
      setRequestId(null)
    }
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>DNS & HTTP Validator</h1>
        <p>Validate DNS resolution and HTTP/HTTPS connectivity</p>
      </header>

      <main className="app-main">
        {!API_ENDPOINT && (
          <div className="error-message">
            <strong>Configuration Error:</strong> API endpoint not configured. Please rebuild the frontend with VITE_API_ENDPOINT environment variable.
          </div>
        )}

        <ValidationForm onSubmit={handleSubmit} disabled={!!requestId && !status?.summary} />

        {error && (
          <div className="error-message">
            <strong>Error:</strong> {error}
          </div>
        )}

        {requestId && (
          <StatusDisplay status={status} requestId={requestId} />
        )}
      </main>
    </div>
  )
}

export default App
