# frozen_string_literal: true

class SetDefaultInvoiceStatus < ActiveRecord::Migration[7.0]
  def change
    add_column :invoices, :cancelled, :boolean, default: false, null: false
    ActiveRecord::Base.connection.execute(<<-SQL.squish
      UPDATE invoices
      SET cancelled = true
      WHERE status = 'inactive'
    SQL
                                         )
    remove_column :invoices, :status, :string
  end
end
