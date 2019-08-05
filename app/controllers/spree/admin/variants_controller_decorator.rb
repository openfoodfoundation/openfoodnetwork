require 'open_food_network/scope_variants_for_search'

Spree::Admin::VariantsController.class_eval do
  helper 'spree/products'

  def create
    on_demand = params[:variant].delete(:on_demand)
    on_hand = params[:variant].delete(:on_hand)

    super

    if @object.present? && @object.valid?
      @object.on_demand = on_demand if on_demand.present?
      @object.on_hand = on_hand.to_i if on_hand.present?
    end
  end

  def search
    scoper = OpenFoodNetwork::ScopeVariantsForSearch.new(params)
    @variants = scoper.search
    render json: @variants, each_serializer: Api::Admin::VariantSerializer
  end

  def destroy
    @variant = Spree::Variant.find(params[:id])
    flash[:success] = if VariantDeleter.new.delete(@variant) # This line changed
                        Spree.t('notice_messages.variant_deleted')
                      else
                        Spree.t('notice_messages.variant_not_deleted')
                      end

    respond_with(@variant) do |format|
      format.html { redirect_to admin_product_variants_url(params[:product_id]) }
      format.js { render_js_for_destroy }
    end
  end

  protected

  def create_before
    option_values = params[:new_variant]
    option_values.andand.each_value { |id| @object.option_values << OptionValue.find(id) }
    @object.save
  end
end
