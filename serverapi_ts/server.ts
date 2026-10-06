import express, { Express } from 'express'
import bodyParser from 'body-parser'
import cors from 'cors'
import dotenv from 'dotenv'

// Initialize dotenv
dotenv.config()

const environment = process.env.ENV || 'development'
if (!process.env.JWT_SECRET) {
  if (environment === 'production') {
    throw new Error('JWT_SECRET must be configured in production')
  }
  process.env.JWT_SECRET = 'watcha-local-development-jwt-secret'
  console.warn('JWT_SECRET is not configured; using a development-only secret')
}

// Initialize App
const app: Express = express()

// Parse incoming JSON requests
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))

// Use Cors
app.use(cors())

// Keep serving legacy uploaded posters while new items use external URLs.
app.use('/uploads', express.static('uploads'))
app.use('/uploads/images', express.static('uploads/images'))

// Routes
import authRoutes from './routes/authRoutes'
import watchlistRoutes from './routes/watchlistRoutes'

// Use Routes
app.use('/api/auth', authRoutes)
app.use('/api/watchlist', watchlistRoutes)
app.get('/api/health', (_req, res) => res.json({ success: true, service: 'watcha-api' }))

app.use((error: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled request error:', error)
  res.status(500).json({ success: false, message: 'Internal server error' })
})

export default app

if (require.main === module) {
  const port: string | number = process.env.PORT || 3000
  app.listen(port, () => {
    console.log(`App listening on port ${port}`)
    console.log(`App listening on env ${environment}`)
    console.log('Press Ctrl+C to quit.')
  })
}