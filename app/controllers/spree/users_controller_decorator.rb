Spree::UsersController.class_eval do
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront
  before_filter :set_credit_card, only: :show

  private

  def set_credit_card
    @credit_card = Spree::CreditCard.new(user: @user)
  end
end
