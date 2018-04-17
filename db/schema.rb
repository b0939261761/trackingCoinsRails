# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_04_16_131906) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "exchanges", comment: "Биржи", force: :cascade do |t|
    t.string "name", limit: 15, default: "", null: false, comment: "Наименование биржи"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата создания записи"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата обновления записи"
    t.index ["name"], name: "index_exchanges_on_name", unique: true
  end

# Could not dump table "notifications" because of following StandardError
#   Unknown type 'e_direction' for column 'direction'

  create_table "pairs", comment: "Валютные пары", force: :cascade do |t|
    t.bigint "exchange_id", null: false, comment: "Биржи"
    t.string "symbol", default: "", null: false, comment: "Символ валют"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата создания записи"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата обновления записи"
    t.index ["exchange_id", "symbol"], name: "index_pairs_on_exchange_id_and_symbol", unique: true
    t.index ["exchange_id"], name: "index_pairs_on_exchange_id"
  end

  create_table "prices", comment: "Котировки", force: :cascade do |t|
    t.bigint "pair_id", null: false, comment: "Валюная пара"
    t.decimal "price", precision: 18, scale: 8, default: "0.0", null: false, comment: "Цена"
    t.datetime "close_time", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата сделки"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата создания записи"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата обновления записи"
    t.index ["pair_id", "close_time"], name: "index_prices_on_pair_id_and_close_time", unique: true
    t.index ["pair_id"], name: "index_prices_on_pair_id"
  end

  create_table "users", comment: "Пользователи", force: :cascade do |t|
    t.string "username", default: "", null: false, comment: "Имя пользователя"
    t.string "email", default: "", null: false, comment: "Почта"
    t.string "password_digest", default: "", null: false, comment: "Зашифрованный пароль"
    t.string "refresh_token", default: "", null: false, comment: "Refresh-токен"
    t.string "string", default: "", null: false, comment: "Refresh-токен"
    t.boolean "confirmed", default: false, null: false, comment: "Подтверждение регистрации"
    t.boolean "boolean", default: false, null: false, comment: "Подтверждение регистрации"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата создания записи"
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Дата обновления записи"
    t.string "lang", limit: 2, default: "en", null: false, comment: "Активный язык"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "notifications", "exchanges", on_delete: :cascade
  add_foreign_key "notifications", "pairs", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "pairs", "exchanges", on_delete: :cascade
  add_foreign_key "prices", "pairs", on_delete: :cascade
end
