Spree::UsersController.class_eval do
  layout 'darkswarm'
  include I18nHelper

  before_filter :set_locale
  before_filter :enable_embedded_shopfront

  # Override of spree_auth_devise default
  # Ignores invoice orders, only order where state: 'complete'
  def show
    @orders = @user.orders.where(state: 'complete').order('completed_at desc')
    @unconfirmed_email = spree_current_user.unconfirmed_email
  end

  # Endpoint for queries to check if a user is already registered
  def registered_email
    user = Spree.user_class.find_by_email params[:email]
    render json: { registered: user.present? }
  end
end
