/**
 * Tests for Authentication
 */

import { hashPassword, comparePassword, generateAccessToken, verifyToken } from '../src/utils/auth'

describe('Authentication', () => {
  describe('Password Hashing', () => {
    it('should hash password and return a string', async () => {
      const password = 'testpassword123'
      const hash = await hashPassword(password)

      expect(hash).toBeDefined()
      expect(typeof hash).toBe('string')
      expect(hash).not.toBe(password)
    })

    it('should compare correct password', async () => {
      const password = 'testpassword123'
      const hash = await hashPassword(password)
      const isValid = await comparePassword(password, hash)

      expect(isValid).toBe(true)
    })

    it('should reject incorrect password', async () => {
      const password = 'testpassword123'
      const hash = await hashPassword(password)
      const isValid = await comparePassword('wrongpassword', hash)

      expect(isValid).toBe(false)
    })
  })

  describe('JWT Tokens', () => {
    it('should generate access token', () => {
      const payload = {
        id: 1,
        uuid: 'test-uuid',
        username: 'testuser',
        role: 'user' as const,
      }

      const token = generateAccessToken(payload)
      expect(token).toBeDefined()
      expect(typeof token).toBe('string')
      expect(token.split('.').length).toBe(3) // JWT has 3 parts
    })

    it('should verify valid token', () => {
      const payload = {
        id: 1,
        uuid: 'test-uuid',
        username: 'testuser',
        role: 'user' as const,
      }

      const token = generateAccessToken(payload)
      const verified = verifyToken(token)

      expect(verified.id).toBe(payload.id)
      expect(verified.username).toBe(payload.username)
    })

    it('should reject invalid token', () => {
      const token = 'invalid.token.here'

      expect(() => {
        verifyToken(token)
      }).toThrow()
    })
  })
})
