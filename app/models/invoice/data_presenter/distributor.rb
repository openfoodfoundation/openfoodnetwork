# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Distributor < Invoice::DataPresenter::Base
      attributes :name, :abn, :acn, :logo_url, :display_invoice_logo, :invoice_text, :email_address,
                 :phone
      attributes_with_presenter :contact, :address, :business_address

      def display_invoice_logo?
        display_invoice_logo == true
      end
    end
  end
end
