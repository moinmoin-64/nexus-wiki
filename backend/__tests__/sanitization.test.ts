/**
 * Tests for Sanitization
 */

import { escapeHtml, isValidUrl, sanitizeHtml, sanitizeText } from '../src/utils/sanitization'

describe('Sanitization', () => {
  describe('HTML Escaping', () => {
    it('should escape HTML special characters', () => {
      const input = '<script>alert("xss")</script>'
      const output = escapeHtml(input)

      expect(output).toBe('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
      expect(output).not.toContain('<script>')
    })

    it('should escape quotes', () => {
      const input = 'He said "hello" and it\'s working'
      const output = escapeHtml(input)

      expect(output).toContain('&quot;')
      expect(output).toContain('&#039;')
    })
  })

  describe('URL Validation', () => {
    it('should accept valid HTTPS URL', () => {
      const validUrl = 'https://example.com/path'
      expect(isValidUrl(validUrl)).toBe(true)
    })

    it('should accept valid HTTP URL', () => {
      const validUrl = 'http://example.com/path'
      expect(isValidUrl(validUrl)).toBe(true)
    })

    it('should reject javascript: protocol', () => {
      const maliciousUrl = 'javascript:alert("xss")'
      expect(isValidUrl(maliciousUrl)).toBe(false)
    })

    it('should reject invalid URL', () => {
      const invalidUrl = 'not a url'
      expect(isValidUrl(invalidUrl)).toBe(false)
    })
  })

  describe('HTML Sanitization', () => {
    it('should sanitize script tags', () => {
      const dirty = '<p>Hello</p><script>alert("xss")</script>'
      const clean = sanitizeHtml(dirty)

      expect(clean).not.toContain('<script>')
      expect(clean).toContain('<p>')
    })

    it('should remove event handlers', () => {
      const dirty = '<img src="x" onerror="alert(1)" />'
      const clean = sanitizeHtml(dirty)

      expect(clean).not.toContain('onerror')
    })

    it('should remove all HTML from plain text mode', () => {
      const dirty = '<script>alert("xss")</script>'
      const clean = sanitizeText(dirty)

      expect(clean).not.toContain('<')
      expect(clean).not.toContain('>')
    })
  })
})
