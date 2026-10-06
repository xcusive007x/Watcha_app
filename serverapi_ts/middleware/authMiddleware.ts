import jwt, { JwtPayload } from 'jsonwebtoken'
import { Request, Response, NextFunction } from 'express'

declare global {
  namespace Express {
    interface Request {
      userId?: number
    }
  }
}

export default function authenticateToken(req: Request, res: Response, next: NextFunction): void {
  const [scheme, token] = String(req.headers.authorization || '').split(' ')
  if (scheme !== 'Bearer' || !token) {
    res.status(401).json({ success: false, message: 'Bearer token is required' })
    return
  }
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || '') as JwtPayload
    const userId = Number(payload.sub)
    if (!Number.isInteger(userId) || userId <= 0) throw new Error('Invalid token subject')
    req.userId = userId
    next()
  } catch {
    res.status(401).json({ success: false, message: 'Invalid or expired token' })
  }
}
