require 'open_food_network/scope_variants_for_search'

Spree::Admin::VariantsController.class_eval do
  helper 'spree/products'

  def search
    scoper = OpenFoodNetwork::ScopeVariantsForSearch.new(params)
    @variants = scoper.search
  end

  def destroy
    @variant = Spree::Variant.find(params[:id])
    if VariantDeleter.new.delete(@variant) # This line changed
      flash[:success] = Spree.t('notice_messages.variant_deleted')
    else
      flash[:success] = Spree.t('notice_messages.variant_not_deleted')
    end

    respond_with(@variant) do |format|
      format.html { redirect_to admin_product_variants_url(params[:product_id]) }
      format.js   { render_js_for_destroy }
    end
  end


  protected

  def create_before
    option_values = params[:new_variant]
    option_values.andand.each_value {|id| @object.option_values << OptionValue.find(id)}
    @object.save
  end
end
