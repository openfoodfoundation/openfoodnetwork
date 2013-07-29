class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :load_data_for_menu
  before_filter :load_data_for_sidebar

  private
  def load_data_for_menu
    @cms_site = Cms::Site.where(:identifier => 'open-food-web').first
  end

  # This is getting sloppy, since @all_distributors is also used for order cycle selection,
  # which is not in the sidebar. I don't like having an application controller method that's
  # coupled to several parts of the code. We might be able to solve this using cells:
  # https://github.com/apotonick/cells
  def load_data_for_sidebar
    sidebar_distributors_limit = false
    sidebar_suppliers_limit = false

    @order_cycles = OrderCycle.active

    @sidebar_suppliers = Enterprise.is_primary_producer.with_supplied_active_products_on_hand.limit(sidebar_suppliers_limit)
    @total_suppliers = Enterprise.is_primary_producer.distinct_count

    @sidebar_distributors = Enterprise.active_distributors.by_name.limit(sidebar_distributors_limit)
    @all_distributors = Enterprise.active_distributors
    @total_distributors = Enterprise.is_distributor.distinct_count
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
