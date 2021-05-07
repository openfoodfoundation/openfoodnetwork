class CartController < BaseController
  before_action :check_authorization

  def populate
    order = current_order(true)

    cart_service = CartService.new(order)

    cart_service.populate(params.slice(:variants, :quantity), true)
    if cart_service.valid?
      order.cap_quantity_at_stock!
      order.recreate_all_fees!

      variant_ids = variant_ids_in(cart_service.variants_h)

      render json: { error: false,
                     stock_levels: VariantsStockLevels.new.call(order, variant_ids) },
             status: :ok
    else
      render json: { error: cart_service.errors.full_messages.join(",") },
             status: :precondition_failed
    end

    populate_variant_attributes
  end

  private

  def variant_ids_in(variants_h)
    variants_h.map { |v| v[:variant_id].to_i }
  end

  def check_authorization
    session[:access_token] ||= params[:token]
    order = Spree::Order.find_by(number: params[:id]) || current_order

    if order
      authorize! :edit, order, session[:access_token]
    else
      authorize! :create, Spree::Order
    end
  end

  def populate_variant_attributes
    order = current_order.reload

    populate_variant_attributes_from_variant(order) if params.key? :variant_attributes
    populate_variant_attributes_from_product(order) if params.key? :quantity
  end

  def populate_variant_attributes_from_variant(order)
    params[:variant_attributes].each do |variant_id, attributes|
      permitted = attributes.permit(:quantity, :max_quantity).to_h.with_indifferent_access
      order.set_variant_attributes(Spree::Variant.find(variant_id), permitted)
    end
  end

  def populate_variant_attributes_from_product(order)
    params[:products].each do |_product_id, variant_id|
      max_quantity = params[:max_quantity].to_i
      order.set_variant_attributes(Spree::Variant.find(variant_id),
                                   max_quantity: max_quantity)
    end
  end
end
