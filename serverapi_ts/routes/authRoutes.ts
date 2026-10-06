import { Router } from 'express'
import * as authController from '../controllers/authController'
import authenticateToken from '../middleware/authMiddleware'

const router = Router()
router.post('/register', authController.register)
router.post('/login', authController.login)
router.get('/profile', authenticateToken, authController.profile)
router.post('/logout', authenticateToken, authController.logout)
export default router
