# frozen_string_literal: true

class DropSuburbs < ActiveRecord::Migration[6.1]
  def change
    drop_table "suburbs", id: :serial, force: :cascade do |t|
      t.string "name", limit: 255
      t.string "postcode", limit: 255
      t.float "latitude"
      t.float "longitude"
      t.integer "state_id"
    end
  end
end
