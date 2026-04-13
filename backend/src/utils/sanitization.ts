/**
 * HTML & Input Sanitization
 * XSS Prevention
 */

import DOMPurify from 'isomorphic-dompurify'

/**
 * Sanitize HTML content
 * Allows safe tags: p, div, span, strong, em, u, h1-h6, ul, ol, li, code, pre, blockquote, a
 */
export const sanitizeHtml = (dirty: string): string => {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: [
      'p',
      'div',
      'span',
      'strong',
      'b',
      'em',
      'i',
      'u',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'ul',
      'ol',
      'li',
      'code',
      'pre',
      'blockquote',
      'a',
      'br',
      'hr',
    ],
    ALLOWED_ATTR: ['href', 'title', 'target', 'rel', 'class'],
    FORCE_BODY: false,
    SANITIZE_DOM: true,
    SAFE_FOR_TEMPLATES: true,
  })
}

/**
 * Sanitize plain text (remove all HTML)
 */
export const sanitizeText = (dirty: string): string => {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: [],
    ALLOWED_ATTR: [],
  })
}

/**
 * Escape special characters for XSS prevention
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
 * Validate URL to prevent javascript: protocol
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
 * Sanitize filename
 */
export const sanitizeFilename = (filename: string): string => {
  return filename
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .replace(/_{2,}/g, '_')
    .substring(0, 255)
}

/**
 * Sanitize markdown (basic)
 */
export const sanitizeMarkdown = (markdown: string): string => {
  // Remove potentially dangerous markdown constructs
  let sanitized = markdown
    .replace(/\[.*?\]\(javascript:.*?\)/gi, '') // Remove js: links
    .replace(/&lt;script\b/gi, '') // Remove script tags
    .replace(/on\w+\s*=/gi, '') // Remove event handlers
  return sanitized
}
