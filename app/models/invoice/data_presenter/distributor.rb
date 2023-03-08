class Invoice::DataPresenter::Distributor < Invoice::DataPresenter::Base
  attributes :name, :abn, :acn, :logo_url, :display_invoice_logo, :invoice_text, :email_address
  attributes_with_presenter :contact, :address, :business_address
  relevant_attributes :name

  def display_invoice_logo?
    display_invoice_logo == true
  end
end
