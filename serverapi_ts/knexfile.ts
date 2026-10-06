require('ts-node/register')
import dotenv from 'dotenv'
dotenv.config()

const connection = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'Watcha_db',
}

module.exports = {
  development: {
    client: 'mysql2',
    connection,
    migrations: {
      tableName: 'knex_migrations',
      extension: 'ts',
      directory: './migrations',
    },
  },
}
