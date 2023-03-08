class Invoice::DataPresenter::Payment < Invoice::DataPresenter::Base
  attributes :amount, :currency, :state
  attributes_with_presenter :payment_method

  def created_at
    datetime = data&.[](:created_at)
    datetime.present? ? Time.zone.parse(datetime) : nil
  end

  def display_amount
    Spree::Money.new(amount, currency: currency)
  end

  def payment_method_name
    payment_method&.name
  end
end
