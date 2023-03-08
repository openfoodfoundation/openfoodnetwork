class Invoice::DataPresenter::ShippingMethod < Invoice::DataPresenter::Base
  attributes :name, :require_ship_address
end
