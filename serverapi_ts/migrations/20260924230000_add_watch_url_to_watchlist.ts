import { Knex } from 'knex'

export async function up(knex: Knex): Promise<void> {
  if (!(await knex.schema.hasColumn('watchlist', 'watch_url'))) {
    await knex.schema.alterTable('watchlist', (table) => {
      table.string('watch_url', 500).nullable()
    })
  }
}

export async function down(knex: Knex): Promise<void> {
  if (await knex.schema.hasColumn('watchlist', 'watch_url')) {
    await knex.schema.alterTable('watchlist', (table) => {
      table.dropColumn('watch_url')
    })
  }
}
