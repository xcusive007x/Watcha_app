import { Router } from 'express'
import authenticateToken from '../middleware/authMiddleware'
import * as watchlistController from '../controllers/watchlistController'

const router = Router()
router.use(authenticateToken)
router.get('/', watchlistController.getAll)
router.get('/:id', watchlistController.getById)
router.post('/', watchlistController.create)
router.put('/:id', watchlistController.update)
router.delete('/:id', watchlistController.remove)
export default router
