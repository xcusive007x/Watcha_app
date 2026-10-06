import mysql from 'mysql2/promise'
import dotenv from 'dotenv'

dotenv.config()

async function main(): Promise<void> {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
  })
  const database = process.env.DB_DATABASE || 'Watcha_db'
  if (!/^[A-Za-z0-9_]+$/.test(database)) throw new Error('DB_DATABASE contains invalid characters')
  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`)
  await connection.end()
  console.log(`Database ${database} is ready`)
}

main().catch((error) => {
  console.error('Unable to create database:', error)
  process.exitCode = 1
})
