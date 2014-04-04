Spree::Api::VariantsController.class_eval do
  def soft_delete
    @variant = scope.find(params[:id])
    authorize! :delete, @variant

    @variant.deleted_at = Time.now()
    if @variant.save
      respond_with(@variant, :status => 204)
    else
      invalid_resource!(@variant)
    end
  end
end
