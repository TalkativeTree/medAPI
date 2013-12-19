# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20131217034413) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "rankings", force: true do |t|
    t.integer  "search_id"
    t.integer  "result_id"
    t.string   "position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", force: true do |t|
    t.integer  "source_id"
    t.string   "url"
    t.string   "title"
    t.text     "summary"
    t.text     "snippet"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_engines", force: true do |t|
    t.string   "name"
    t.string   "base_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "search_engines_terms", id: false, force: true do |t|
    t.integer "search_engine_id", null: false
    t.integer "term_id",          null: false
  end

  create_table "searches", force: true do |t|
    t.string   "tokens",     default: [], array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches_terms", id: false, force: true do |t|
    t.integer "search_id", null: false
    t.integer "term_id",   null: false
  end

  create_table "sources", force: true do |t|
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "terms", force: true do |t|
    t.string   "name"
    t.integer  "topic_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
