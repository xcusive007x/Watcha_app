import { Request, Response } from 'express'
import db from '../utils/db'

const statuses = ['wishlist', 'watching', 'completed']
const types = ['movie', 'series']

function validatePayload(body: Record<string, unknown>, partial = false): string | null {
  if (!partial && !String(body.title || '').trim()) return 'title is required'
  if (body.title !== undefined && !String(body.title).trim()) return 'title cannot be empty'
  if (body.type !== undefined && !types.includes(String(body.type))) return 'type must be movie or series'
  if (body.status !== undefined && !statuses.includes(String(body.status))) return 'invalid status'
  if (body.year !== undefined && body.year !== null && (!Number.isInteger(Number(body.year)) || Number(body.year) < 1888 || Number(body.year) > new Date().getFullYear() + 2)) return 'year is invalid'
  if (body.rating !== undefined && body.rating !== null && (!Number.isInteger(Number(body.rating)) || Number(body.rating) < 1 || Number(body.rating) > 5)) return 'rating must be between 1 and 5'
  if (body.rating !== undefined && body.rating !== null && body.status !== undefined && body.status !== 'completed') return 'rating is only allowed for completed items'
  return null
}

function selectFields(query: any): any {
  return query.select('id', 'title', 'type', 'year', 'status', 'rating', 'note', 'poster_url', 'watch_url', 'created_at', 'updated_at')
}

export async function getAll(req: Request, res: Response): Promise<void> {
  try {
    let query = db('watchlist').where({ user_id: req.userId })
    if (req.query.status) query = query.where({ status: String(req.query.status) })
    if (req.query.type) query = query.where({ type: String(req.query.type) })
    if (req.query.search) query = query.where('title', 'like', `%${String(req.query.search)}%`)
    const items = await selectFields(query.orderBy('created_at', 'desc'))
    res.json({ success: true, data: items })
  } catch (error) {
    console.error('Watchlist lookup failed:', error)
    res.status(500).json({ success: false, message: 'Unable to load watchlist' })
  }
}

export async function getById(req: Request, res: Response): Promise<void> {
  try {
    const item = await selectFields(db('watchlist').where({ id: req.params.id, user_id: req.userId })).first()
    if (!item) {
      res.status(404).json({ success: false, message: 'Watchlist item not found' })
      return
    }
    res.json({ success: true, data: item })
  } catch (error) {
    console.error('Watchlist item lookup failed:', error)
    res.status(500).json({ success: false, message: 'Unable to load watchlist item' })
  }
}

export async function create(req: Request, res: Response): Promise<void> {
  const error = validatePayload(req.body)
  if (error) {
    res.status(400).json({ success: false, message: error })
    return
  }
  const status = req.body.status || 'wishlist'
  if (req.body.rating != null && status !== 'completed') {
    res.status(400).json({ success: false, message: 'rating is only allowed for completed items' })
    return
  }
  try {
    const [id] = await db('watchlist').insert({
      user_id: req.userId,
      title: String(req.body.title).trim(),
      type: req.body.type,
      year: req.body.year ?? null,
      status,
      rating: req.body.rating ?? null,
      note: req.body.note ?? null,
      poster_url: req.body.posterUrl ?? req.body.poster_url ?? null,
      watch_url: req.body.watchUrl ?? req.body.watch_url ?? null,
    })
    const item = await selectFields(db('watchlist').where({ id, user_id: req.userId })).first()
    res.status(201).json({ success: true, data: item })
  } catch (error) {
    console.error('Watchlist create failed:', error)
    res.status(500).json({ success: false, message: 'Unable to create watchlist item' })
  }
}

export async function update(req: Request, res: Response): Promise<void> {
  const error = validatePayload(req.body, true)
  if (error) {
    res.status(400).json({ success: false, message: error })
    return
  }
  try {
    const current = await db('watchlist').where({ id: req.params.id, user_id: req.userId }).first()
    if (!current) {
      res.status(404).json({ success: false, message: 'Watchlist item not found' })
      return
    }
    const nextStatus = req.body.status ?? current.status
    const nextRating = nextStatus === 'completed'
      ? (req.body.rating !== undefined ? req.body.rating : current.rating)
      : null
    await db('watchlist').where({ id: req.params.id, user_id: req.userId }).update({
      ...(req.body.title !== undefined && { title: String(req.body.title).trim() }),
      ...(req.body.type !== undefined && { type: req.body.type }),
      ...(req.body.year !== undefined && { year: req.body.year }),
      ...(req.body.status !== undefined && { status: req.body.status }),
      ...(req.body.rating !== undefined || nextStatus !== 'completed' ? { rating: nextStatus === 'completed' ? nextRating : null } : {}),
      ...(req.body.note !== undefined && { note: req.body.note }),
      ...((req.body.posterUrl !== undefined || req.body.poster_url !== undefined) && {
        poster_url: req.body.posterUrl ?? req.body.poster_url ?? null,
      }),
      ...((req.body.watchUrl !== undefined || req.body.watch_url !== undefined) && {
        watch_url: req.body.watchUrl ?? req.body.watch_url ?? null,
      }),
    })
    const item = await selectFields(db('watchlist').where({ id: req.params.id, user_id: req.userId })).first()
    res.json({ success: true, data: item })
  } catch (error) {
    console.error('Watchlist update failed:', error)
    res.status(500).json({ success: false, message: 'Unable to update watchlist item' })
  }
}

export async function remove(req: Request, res: Response): Promise<void> {
  try {
    const deleted = await db('watchlist').where({ id: req.params.id, user_id: req.userId }).del()
    if (!deleted) {
      res.status(404).json({ success: false, message: 'Watchlist item not found' })
      return
    }
    res.json({ success: true, message: 'Watchlist item deleted' })
  } catch (error) {
    console.error('Watchlist delete failed:', error)
    res.status(500).json({ success: false, message: 'Unable to delete watchlist item' })
  }
}
