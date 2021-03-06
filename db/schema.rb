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

ActiveRecord::Schema.define(version: 20140513024639) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_keys", force: true do |t|
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "parent",                  default: false
    t.string   "google_product_category"
  end

  create_table "product_group_categories", force: true do |t|
    t.integer  "category_id"
    t.integer  "product_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_groups", force: true do |t|
    t.string   "name"
    t.string   "bti_id"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "brand"
    t.string   "status"
    t.integer  "shopify_id"
    t.boolean  "on_shopify",  default: false
  end

  create_table "products", force: true do |t|
    t.string   "name"
    t.string   "bti_id"
    t.string   "stock"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "product_group_id"
    t.string   "model"
    t.float    "msrp_price"
    t.float    "sale_price"
    t.float    "regular_price"
    t.string   "photo_url"
    t.integer  "shopify_id"
    t.boolean  "authorization_required", default: false
    t.string   "status"
    t.string   "mpn"
    t.boolean  "on_shopify",             default: false
    t.float    "map_price"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "bti_customer_number"
    t.string   "bti_uname"
    t.string   "bti_pass"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "variations", force: true do |t|
    t.string   "value"
    t.string   "key"
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
