Spree::UsersController.class_eval do
  layout 'darkswarm'

  before_filter :enable_embedded_shopfront
  before_filter :set_credit_card, only: :show

  # Override of spree_auth_devise default
  # Ignores invoice orders, only order where state: 'complete'
  def show
    @orders = @user.orders.where(state: 'complete').order('completed_at desc')

    return unless Spree::Config.accounts_distributor_id

    @orders = @orders.where('distributor_id != ?', Spree::Config.accounts_distributor_id)
  end

  private

  def set_credit_card
    @credit_card = Spree::CreditCard.new(user: @user)
  end
end
