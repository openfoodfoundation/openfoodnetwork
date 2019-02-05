require 'open_food_network/scope_variant_to_hub'

Spree::Api::ShipmentsController.class_eval do
  def create
    variant = Spree::Variant.find(params[:variant_id])
    OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)

    quantity = params[:quantity].to_i
    @shipment = @order.shipments.create(:stock_location_id => params[:stock_location_id])
    @order.contents.add(variant, quantity, nil, @shipment)

    @shipment.refresh_rates
    @shipment.save!

    respond_with(@shipment.reload, :default_template => :show)
  end

  def add
    variant = Spree::Variant.find(params[:variant_id])
    OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)

    quantity = params[:quantity].to_i

    @order.contents.add(variant, quantity, nil, @shipment)

    respond_with(@shipment, :default_template => :show)
  end

  def remove
    variant = Spree::Variant.find(params[:variant_id])
    OpenFoodNetwork::ScopeVariantToHub.new(@order.distributor).scope(variant)

    quantity = params[:quantity].to_i

    @order.contents.remove(variant, quantity, @shipment)
    @shipment.reload if @shipment.persisted?
    respond_with(@shipment, :default_template => :show)
  end
end
