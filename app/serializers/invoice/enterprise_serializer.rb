# frozen_string_literal: false

class Invoice
  class EnterpriseSerializer < ActiveModel::Serializer
    attributes :name, :abn, :acn, :invoice_text, :email_address, :display_invoice_logo, :logo_url,
               :phone
    has_one :contact, serializer: Invoice::UserSerializer
    has_one :business_address, serializer: Invoice::AddressSerializer
    has_one :address, serializer: Invoice::AddressSerializer
    def logo_url
      object.logo_url(:small)
    end
  end
end
