class Invoice::DataPresenter::Base
  attr :data
  def initialize(data)
    @data = data
  end
  extend Invoice::DataPresenterAttributes
end
