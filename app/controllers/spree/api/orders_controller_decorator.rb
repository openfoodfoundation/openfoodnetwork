Spree::Api::OrdersController.class_eval do

  # We need to add expections for collection actions other than :index here
  # because Spree's API controller causes authorize_read! to be called, which
  # results in an ActiveRecord::NotFound Exception as the order object is not
  # defined for collection actions
  before_filter :authorize_read!, :except => [:managed]

  def managed
    @orders = Spree::Order.ransack(params[:q]).result.managed_by(current_api_user).page(params[:page]).per(params[:per_page])
    respond_with(@orders, default_template: :index)
  end
end