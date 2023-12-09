# frozen_string_literal: true

class EnableFeatureBackroundReports < ActiveRecord::Migration[7.0]
  def up
    Flipper.enable("background_reports")
  end
end
