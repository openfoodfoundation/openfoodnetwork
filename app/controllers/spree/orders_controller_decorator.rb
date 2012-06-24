Spree::OrdersController.class_eval do
  before_filter :populate_order_distributor, :only => :populate

  def populate_order_distributor
    @distributor = Spree::Distributor.find params[:distributor_id]
    if @distributor.nil?
      return false
    end

  end
end
