Spree::Api::ProductsController.class_eval do
  def managed
    @products = product_scope.ransack(params[:q]).result.managed_by(current_api_user).page(params[:page]).per(params[:per_page])
    respond_with(@products, default_template: :index)
  end

end
