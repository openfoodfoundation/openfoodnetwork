Spree::Api::VariantsController.class_eval do
  def soft_delete
    @variant = scope.find(params[:variant_id])
    authorize! :delete, @variant

    VariantDeleter.new.delete(@variant)
    respond_with @variant, status: 204
  end
end
