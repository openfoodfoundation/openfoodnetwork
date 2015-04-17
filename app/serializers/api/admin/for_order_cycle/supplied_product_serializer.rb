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
    object.variants.map do |variant|
      { id: variant.id, label: variant.full_name }
    end
  end
end
