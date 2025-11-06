import { useState } from 'react'

function ValidationForm({ onSubmit, disabled }) {
  const [target, setTarget] = useState('')

  const handleSubmit = (e) => {
    e.preventDefault()
    if (target.trim()) {
      onSubmit(target.trim())
      setTarget('')
    }
  }

  return (
    <form onSubmit={handleSubmit} className="validation-form">
      <div className="form-group">
        <label htmlFor="target">Target Domain:</label>
        <input
          id="target"
          type="text"
          value={target}
          onChange={(e) => setTarget(e.target.value)}
          placeholder="example.com"
          disabled={disabled}
          required
        />
      </div>
      <button type="submit" disabled={disabled || !target.trim()}>
        {disabled ? 'Validation in progress...' : 'Validate'}
      </button>
    </form>
  )
}

export default ValidationForm
