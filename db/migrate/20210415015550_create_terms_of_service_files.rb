# frozen_string_literal: true

class CreateTermsOfServiceFiles < ActiveRecord::Migration[5.0]
  def change
    # rubocop:disable Style/SymbolProc
    create_table :terms_of_service_files do |t|
      t.timestamps
    end
    # rubocop:enable Style/SymbolProc
  end
end
