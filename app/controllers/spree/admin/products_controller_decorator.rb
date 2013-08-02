Spree::Admin::ProductsController.class_eval do
  before_filter :load_spree_api_key, :only => :bulk_edit

  alias_method :location_after_save_original, :location_after_save

  respond_to :json, :only => :clone

  #respond_override :clone => { :json => {:success => lambda { redirect_to bulk_index_admin_products_url+"?q[id_eq]=#{@new.id}" } } }

  def bulk_update
    collection_hash = Hash[params[:_json].each_with_index.map { |p,i| [i,p] }]
    product_set = Spree::ProductSet.new({:collection_attributes => collection_hash})

    if product_set.save
      redirect_to "/api/products?template=bulk_index"
    else
      render :nothing => true
    end
  end

  protected
  def location_after_save
    if URI(request.referer).path == '/admin/products/bulk_edit'
      bulk_edit_admin_products_url
    else
      location_after_save_original
    end
  end

  def collection
    # This method is copied directly from the spree product controller, except where we narrow the search below with the managed_by search to support
    # enterprise users.
    # TODO: There has to be a better way!!!
    return @collection if @collection.present?
    params[:q] ||= {}
    params[:q][:deleted_at_null] ||= "1"

    params[:q][:s] ||= "name asc"

    @search = super.ransack(params[:q])
    @collection = @search.result.
      managed_by(spree_current_user). # this line is added to the original spree code!!!!!
      group_by_products_id.
      includes(product_includes).
      page(params[:page]).
      per(Spree::Config[:admin_products_per_page])

    if params[:q][:s].include?("master_default_price_amount")
      # PostgreSQL compatibility
      @collection = @collection.group("spree_prices.amount")
    end
    @collection
  end

  private

  def load_spree_api_key
    current_user.generate_spree_api_key! unless spree_current_user.spree_api_key
    @spree_api_key = spree_current_user.spree_api_key
  end
end