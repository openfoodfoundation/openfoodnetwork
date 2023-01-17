# frozen_string_literal: true

class EnableStatsExtension < ActiveRecord::Migration[6.1]
  def change
    # Most production servers have this already. Enabling twice isn't harmful.
    enable_extension "pg_stat_statements"
  end
end
