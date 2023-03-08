class Invoice::DataPresenter::Product < Invoice::DataPresenter::Base
  attributes :name
  attributes_with_presenter :supplier
end