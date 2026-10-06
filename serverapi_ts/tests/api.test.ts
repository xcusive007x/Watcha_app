import assert from 'node:assert/strict'
import { once } from 'node:events'
import { Server } from 'node:http'
import { after, before, test } from 'node:test'
import app from '../server'

let server: Server
let baseUrl: string

before(async () => {
  server = app.listen(0, '127.0.0.1')
  await once(server, 'listening')
  const address = server.address()
  assert(address && typeof address !== 'string')
  baseUrl = `http://127.0.0.1:${address.port}`
})

after(async () => {
  if (server) {
    server.close()
    await once(server, 'close')
  }
})

test('health endpoint reports the API as available', async () => {
  const response = await fetch(`${baseUrl}/api/health`)
  assert.equal(response.status, 200)
  assert.deepEqual(await response.json(), { success: true, service: 'watcha-api' })
})

test('watchlist endpoint requires authentication', async () => {
  const response = await fetch(`${baseUrl}/api/watchlist`)
  assert.equal(response.status, 401)
  assert.equal((await response.json()).success, false)
})

test('login rejects missing credentials without accessing the database', async () => {
  const response = await fetch(`${baseUrl}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  })
  assert.equal(response.status, 400)
  assert.equal((await response.json()).message, 'email and password are required')
})

test('registration rejects an invalid payload without accessing the database', async () => {
  const response = await fetch(`${baseUrl}/api/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Watcha User', email: 'user@example.com', password: 'short' }),
  })
  assert.equal(response.status, 400)
})
