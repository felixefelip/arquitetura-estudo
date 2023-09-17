# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_09_17_220935) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "academico_alunos", force: :cascade do |t|
    t.string "cpf", null: false
    t.string "email", null: false
    t.string "nome", null: false
    t.string "senha"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "academico_cursos", force: :cascade do |t|
    t.string "titulo"
    t.string "url"
    t.string "icone"
    t.boolean "assitido"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "finance_cards", force: :cascade do |t|
    t.string "owner_full_name"
    t.string "number"
    t.integer "month_expiration"
    t.integer "year_expiration"
    t.integer "security_code"
    t.bigint "finance_client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["finance_client_id"], name: "index_finance_cards_on_finance_client_id"
  end

  create_table "finance_clients", force: :cascade do |t|
    t.string "full_name"
    t.string "email"
    t.string "document"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "marketing_leads", force: :cascade do |t|
    t.string "full_name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
  end

  create_table "telefones", force: :cascade do |t|
    t.string "ddd"
    t.string "numero"
    t.bigint "academico_aluno_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academico_aluno_id"], name: "index_telefones_on_academico_aluno_id"
  end

  add_foreign_key "finance_cards", "finance_clients"
  add_foreign_key "telefones", "academico_alunos"
end
