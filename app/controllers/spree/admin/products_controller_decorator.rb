Spree::Admin::ProductsController.class_eval do
  before_filter :load_product_set, :only => :bulk_index
  
  alias_method :location_after_save_original, :location_after_save
  
  def bulk_index
    respond_to do |format|
      format.html
      format.json
    end
  end
  
  protected
  def location_after_save
    if URI(request.referer).path == '/admin/products/bulk_index' 
      bulk_index_admin_products_url
    else 
      location_after_save_original
    end
  end
  
  private
  def load_product_set
    @product_set = Spree::ProductSet.new :collection => collection
  end
end