class UpdateItemNameToProductInOdReport < ActiveRecord::Migration[7.0]
  class ReportRenderingOptions < ActiveRecord::Base
    self.belongs_to_required_by_default = false

    belongs_to :user, class_name: "Spree::User"
    serialize :options, Hash, coder: YAML
  end

  # OD: Orders and Distributors
  def up
    # adding subtype filter just to be safe
    options = ReportRenderingOptions.where(report_type: 'orders_and_distributors', report_subtype: nil)

    options.find_each do |option|
      begin
        fields_to_show = option.options[:fields_to_show]
        next if fields_to_show&.exclude?('item_name')

        fields_to_show.delete('item_name')
        fields_to_show << 'product'
        option.save
      rescue StandardError => e
        puts "Failed to update rendering option with id: #{option.id}"
        puts "Error: #{e.message}"
      end
    end
  end

  def down
    options = ReportRenderingOptions.where(report_type: 'orders_and_distributors', report_subtype: nil)

    options.find_each do |option|
      begin
        fields_to_show = option.options[:fields_to_show]
        next if fields_to_show&.exclude?('product')

        fields_to_show.delete('product')
        fields_to_show << 'item_name'
        option.update(options: option.options)
      rescue StandardError => e
        puts "Failed to revert rendering option with id: #{option.id}"
        puts "Error: #{e.message}"
      end
    end
  end
end
