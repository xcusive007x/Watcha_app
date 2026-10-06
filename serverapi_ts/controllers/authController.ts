import bcrypt from 'bcrypt'
import jwt from 'jsonwebtoken'
import { Request, Response } from 'express'
import db from '../utils/db'

function secret(): string {
  const value = process.env.JWT_SECRET
  if (!value) throw new Error('JWT_SECRET is not configured')
  return value
}

export async function register(req: Request, res: Response): Promise<void> {
  const { name, firstname, lastname, email, password } = req.body
  const normalizedEmail = String(email || '').trim().toLowerCase()
  const displayName = String(name || `${firstname || ''} ${lastname || ''}`).trim()

  if (!displayName || !normalizedEmail || !password || String(password).length < 8) {
    res.status(400).json({ success: false, message: 'name, email and password (minimum 8 characters) are required' })
    return
  }

  try {
    // Fail before writing to the database when JWT configuration is invalid.
    const jwtSecret = secret()
    const existing = await db('users').where({ email: normalizedEmail }).first()
    if (existing) {
      res.status(409).json({ success: false, message: 'Email already exists' })
      return
    }
    const [id] = await db('users').insert({
      name: displayName,
      email: normalizedEmail,
      password_hash: await bcrypt.hash(String(password), 12),
    })
    const user = { id, name: displayName, email: normalizedEmail }
    res.status(201).json({
      success: true,
      data: { user, token: jwt.sign({ sub: Number(id) }, jwtSecret, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }) },
    })
  } catch (error) {
    console.error('Register failed:', error)
    res.status(500).json({ success: false, message: 'Unable to register user' })
  }
}

export async function login(req: Request, res: Response): Promise<void> {
  const email = String(req.body.email || '').trim().toLowerCase()
  const password = String(req.body.password || '')
  if (!email || !password) {
    res.status(400).json({ success: false, message: 'email and password are required' })
    return
  }
  try {
    const jwtSecret = secret()
    const user = await db('users').where({ email }).first()
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      res.status(401).json({ success: false, message: 'Invalid email or password' })
      return
    }
    res.json({
      success: true,
      data: {
        user: { id: user.id, name: user.name, email: user.email },
        token: jwt.sign({ sub: user.id }, jwtSecret, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }),
      },
    })
  } catch (error) {
    console.error('Login failed:', error)
    res.status(500).json({ success: false, message: 'Unable to login' })
  }
}

export async function profile(req: Request, res: Response): Promise<void> {
  try {
    const user = await db('users').select('id', 'name', 'email', 'created_at').where({ id: req.userId }).first()
    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' })
      return
    }
    res.json({ success: true, data: user })
  } catch (error) {
    console.error('Profile lookup failed:', error)
    res.status(500).json({ success: false, message: 'Unable to load profile' })
  }
}

export function logout(_req: Request, res: Response): void {
  res.json({ success: true, message: 'Logged out successfully' })
}
