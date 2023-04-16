class Invoice::DataPresenter::ShippingMethod < Invoice::DataPresenter::Base
  attributes :id, :name, :require_ship_address
  invoice_generation_attributes :id
end
