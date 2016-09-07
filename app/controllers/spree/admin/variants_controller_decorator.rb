require 'open_food_network/permissions'

Spree::Admin::VariantsController.class_eval do
  helper 'spree/products'
  before_filter :load_price_estimate_context, only: [:price_estimate]

  respond_to :json

  def search
    search_params = { :product_name_cont => params[:q], :sku_cont => params[:q] }

    @variants = Spree::Variant.where(is_master: false).ransack(search_params.merge(:m => 'or')).result

    if params[:order_cycle_id].present?
      order_cycle = OrderCycle.find params[:order_cycle_id]
      @variants = @variants.in_order_cycle(order_cycle)
    end

    if params[:distributor_id].present?
      distributor = Enterprise.find params[:distributor_id]
      @variants = @variants.in_distributor(distributor)
      scoper = OpenFoodNetwork::ScopeVariantToHub.new(distributor)
      # Perform scoping after all filtering is done.
      # Filtering could be a problem on scoped variants.
      @variants.each { |v| scoper.scope(v) }
    end
  end

  def price_estimate
    if @shop && @schedule && @order_cycle
      fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(@shop, @order_cycle)
      OpenFoodNetwork::ScopeVariantToHub.new(@shop).scope(@variant)
      render json: @variant, serializer: Api::Admin::EstimatedVariantSerializer, fee_calculator: fee_calculator
    else
      render json: { errors: ["Unauthorized"], status: :unprocessable_entity }
    end
  end

  def destroy
    @variant = Spree::Variant.find(params[:id])
    @variant.delete # This line changed, as well as removal of following conditional
    flash[:success] = I18n.t('notice_messages.variant_deleted')

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

  private

  # Allows us to use a variant_id only to look up a price estimate
  def parent_data
    return super unless action == :price_estimate
    nil
  end

  def permissions
    OpenFoodNetwork::Permissions.new(spree_current_user)
  end

  def load_price_estimate_context
    @shop = Enterprise.managed_by(spree_current_user).find_by_id(params[:shop_id])
    @schedule = permissions.editable_schedules.find_by_id(params[:schedule_id])
    @order_cycle = @schedule.andand.current_or_next_order_cycle
  end
end
