# frozen_string_literal: true

class RenameOffendingMigrations < ActiveRecord::Migration[7.0]
  MIGRATION_IDS = {
    '20231002000136871': "20231002000136",
    '20231002000136872': "20231002000137",
    '20231002000136876': "20231002000138",
    '20231002000136877': "20231002000139",
    '20231002000136879': "20231002000140",
    '20231002000136926': "20231002000141",
    '20231002000136952': "20231002000142",
    '20231002000136955': "20231002000143",
    '20231002000136959': "20231002000144",
    '20231002000136976': "20231002000145",
    '20231002000137115': "20231002000146",
    '20231002000137116': "20231002000147",
    '20231003000823494': "20231003000823",
  }.freeze

  def up
    MIGRATION_IDS.each do |bad_id, good_id|
      execute <<~SQL.squish
        UPDATE schema_migrations
           SET version='#{good_id}'
         WHERE version='#{bad_id}'
      SQL
    end
  end

  def down
    MIGRATION_IDS.each do |bad_id, good_id|
      execute <<~SQL.squish
        UPDATE schema_migrations
           SET version='#{bad_id}'
         WHERE version='#{good_id}'
      SQL
    end
  end
end
