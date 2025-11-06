import { useEffect, useRef } from 'react'

export function usePolling(getUrl, onData, interval = 2000, dependencies = []) {
  const pollingRef = useRef(null)
  const shouldStopRef = useRef(false)
  const getUrlRef = useRef(getUrl)
  const onDataRef = useRef(onData)

  // Update refs when functions change
  useEffect(() => {
    getUrlRef.current = getUrl
    onDataRef.current = onData
  }, [getUrl, onData])

  useEffect(() => {
    // Stop previous polling
    shouldStopRef.current = true
    if (pollingRef.current) {
      clearTimeout(pollingRef.current)
      pollingRef.current = null
    }

    // Reset for new polling
    shouldStopRef.current = false

    const poll = async () => {
      if (shouldStopRef.current) {
        return
      }

      const url = getUrlRef.current()
      if (!url) {
        // If no URL, wait and try again
        pollingRef.current = setTimeout(poll, interval)
        return
      }

      try {
        const response = await fetch(url)
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        const data = await response.json()
        const shouldStop = onDataRef.current(data)

        if (shouldStop) {
          shouldStopRef.current = true
          return
        }
      } catch (error) {
        console.error('Polling error:', error)
        // Continue polling even on error
      }

      if (!shouldStopRef.current) {
        pollingRef.current = setTimeout(poll, interval)
      }
    }

    poll()

    return () => {
      shouldStopRef.current = true
      if (pollingRef.current) {
        clearTimeout(pollingRef.current)
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [interval, ...dependencies])
}
