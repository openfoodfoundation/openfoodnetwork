class Api::Admin::ForOrderCycle::SuppliedProductSerializer < ActiveModel::Serializer
  attributes :name, :supplier_name, :image_url, :master_id, :variants

  def supplier_name
    object.supplier.andand.name
  end

  def image_url
    object.images.present? ? object.images.first.attachment.url(:mini) : nil
  end

  def master_id
    object.master.id
  end

  def variants
    variants = if order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      object.variants.visible_for(order_cycle.coordinator)
    else
      object.variants
    end
    variants.map { |variant| { id: variant.id, label: variant.full_name } }
  end

  private

  def order_cycle
    options[:order_cycle]
  end
end
