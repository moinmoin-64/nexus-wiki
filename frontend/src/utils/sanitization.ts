/**
 * Frontend Sanitization Utilities
 * XSS Prevention on Client-Side
 */

/**
 * Escape HTML special characters
 */
export const escapeHtml = (text: string): string => {
  const map: { [key: string]: string } = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  }
  return text.replace(/[&<>"']/g, (m) => map[m])
}

/**
 * Validate URL (prevent javascript: protocol)
 */
export const isValidUrl = (url: string): boolean => {
  try {
    const parsed = new URL(url)
    return parsed.protocol === 'http:' || parsed.protocol === 'https:'
  } catch {
    return false
  }
}

/**
 * Sanitize user input
 */
export const sanitizeInput = (input: string): string => {
  return input.trim().replace(/[<>]/g, '')
}

/**
 * Sanitize document title
 */
export const sanitizeTitle = (title: string): string => {
  return title.trim().substring(0, 255)
}
