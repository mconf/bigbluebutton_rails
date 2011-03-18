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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110318183557) do

  create_table "bigbluebutton_rooms", :force => true do |t|
    t.integer  "bigbluebutton_server_id"
    t.string   "meeting_id"
    t.string   "meeting_name"
    t.string   "attendee_password"
    t.string   "moderator_password"
    t.string   "welcome_msg"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "bigbluebutton_rooms", ["bigbluebutton_server_id"], :name => "index_bigbluebutton_rooms_on_bigbluebutton_server_id"
  add_index "bigbluebutton_rooms", ["meeting_id"], :name => "index_bigbluebutton_rooms_on_meeting_id", :unique => true

  create_table "bigbluebutton_servers", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
