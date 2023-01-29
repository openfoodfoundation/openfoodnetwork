# frozen_string_literal: true

class AddWhatsappPhoneToEnterprises < ActiveRecord::Migration[6.1]
  def change
    add_column :enterprises, :whatsapp_phone, :string, limit: 255
  end
end
