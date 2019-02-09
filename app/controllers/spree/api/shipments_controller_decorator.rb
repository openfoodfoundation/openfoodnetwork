require 'open_food_network/scope_variant_to_hub'

Spree::Api::ShipmentsController.class_eval do
  def create
    variant = scoped_variant(params[:variant_id])
    quantity = params[:quantity].to_i
    @shipment = get_or_create_shipment(params[:stock_location_id])

    @order.contents.add(variant, quantity, nil, @shipment)

    @shipment.refresh_rates
    @shipment.save!

    respond_with(@shipment.reload, default_template: :show)
  end

  def add
    variant = scoped_variant(params[:variant_id])
    quantity = params[:quantity].to_i

    @order.contents.add(variant, quantity, nil, @shipment)

    respond_with(@shipment, default_template: :show)
  end

  def remove
    variant = scoped_variant(params[:variant_id])
    quantity = params[:quantity].to_i

    @order.contents.remove(variant, quantity, @shipment)
    @shipment.reload if @shipment.persisted?

    respond_with(@shipment, default_template: :show)
  end

  private

  def scoped_variant(variant_id)
    variant = Spree::Variant.find(variant_id)
    OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)
    variant
  end

  def get_or_create_shipment(stock_location_id)
    @order.shipment || @order.shipments.create(stock_location_id: stock_location_id)
  end
end
