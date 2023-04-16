class Invoice::DataPresenter::PaymentMethod < Invoice::DataPresenter::Base
  attributes :id,:name, :description
  invoice_generation_attributes :id
end
