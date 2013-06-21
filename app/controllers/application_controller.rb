class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_data_for_menu
  before_filter :load_data_for_sidebar

  private
  def load_data_for_menu
    @cms_site = Cms::Site.where(:identifier => 'open-food-web').first
  end

  def load_data_for_sidebar
    sidebar_distributors_limit = 5 #set false to disable TODO: move to app config
    sidebar_suppliers_limit = 5
    @sidebar_distributors = Enterprise.is_distributor.with_distributed_active_products_on_hand.by_name.limit(sidebar_distributors_limit)
    @total_distributors = Enterprise.is_distributor.with_distributed_active_products_on_hand.by_name.distinct_count
    @sidebar_suppliers = Enterprise.is_primary_producer.with_supplied_active_products_on_hand.limit(sidebar_suppliers_limit) 
    @total_suppliers = Enterprise.is_primary_producer.with_supplied_active_products_on_hand.distinct_count
  end

  # All render calls within the block will be performed with the specified format
  # Useful for rendering html within a JSON response, particularly if the specified
  # template or partial then goes on to render further partials without specifying
  # their format.
  def with_format(format, &block)
    old_formats = formats
    self.formats = [format]
    block.call
    self.formats = old_formats
    nil
  end

end
