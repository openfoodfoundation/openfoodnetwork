class AddDefaultAndNotNullToProducerPropertiesPosition < ActiveRecord::Migration
  def change
    ProducerProperty.where(position: nil).each do |producer_property|
      producer_property.update_attribute(:position, 0)
    end

    change_column :producer_properties, :position, :integer, null: false, default: 0
  end
end
