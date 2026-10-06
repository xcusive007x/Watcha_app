import { Knex } from 'knex'

export async function up(knex: Knex): Promise<void> {
  await knex.schema.createTable('watchlist', (table) => {
    table.bigIncrements('id').primary()
    table.bigInteger('user_id').unsigned().notNullable()
    table.string('title', 255).notNullable()
    table.enu('type', ['movie', 'series']).notNullable()
    table.integer('year').unsigned().nullable()
    table.enu('status', ['wishlist', 'watching', 'completed']).notNullable().defaultTo('wishlist')
    table.tinyint('rating').unsigned().nullable()
    table.text('note').nullable()
    table.string('poster_url', 500).nullable()
    table.timestamps(true, true)

    table.foreign('user_id').references('id').inTable('users').onDelete('CASCADE')
    table.index(['user_id', 'status'], 'idx_watchlist_user_status')
    table.index(['user_id', 'title'], 'idx_watchlist_user_title')
  })

  await knex.raw(
    'ALTER TABLE `watchlist` ADD CONSTRAINT `chk_watchlist_rating` CHECK (`rating` IS NULL OR `rating` BETWEEN 1 AND 5)',
  )
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('watchlist')
}
