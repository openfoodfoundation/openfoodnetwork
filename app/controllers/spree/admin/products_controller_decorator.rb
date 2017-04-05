require 'open_food_network/spree_api_key_loader'
require 'open_food_network/referer_parser'

Spree::Admin::ProductsController.class_eval do
  include OpenFoodNetwork::SpreeApiKeyLoader
  include OrderCyclesHelper
  before_filter :load_form_data, :only => [:bulk_edit, :new, :create, :edit, :update]
  before_filter :load_spree_api_key, :only => [:bulk_edit, :variant_overrides]
  before_filter :strip_new_properties, only: [:create, :update]

  respond_override create: { html: {
    success: lambda {
      if params[:button] == "add_another"
        redirect_to new_admin_product_path
      else
        redirect_to '/admin/products/bulk_edit'
      end
    },
    failure: lambda {
      render :new
    } } }

  def product_distributions
  end

  def bulk_update
    collection_hash = Hash[params[:products].each_with_index.map { |p,i| [i,p] }]
    product_set = Spree::ProductSet.new({:collection_attributes => collection_hash})

    params[:filters] ||= {}
    bulk_index_query = params[:filters].reduce("") do |string, filter|
      "#{string}q[#{filter[:property][:db_column]}_#{filter[:predicate][:predicate]}]=#{filter[:value]};"
    end

    # Ensure we're authorised to update all products
    product_set.collection.each { |p| authorize! :update, p }

    if product_set.save
      redirect_to "/api/products/bulk_products?page=1;per_page=500;#{bulk_index_query}"
    else
      if product_set.errors.present?
        render json: { errors: product_set.errors }, status: 400
      else
        render :nothing => true, :status => 500
      end
    end
  end


  protected

  def location_after_save_with_bulk_edit
    referer_path = OpenFoodNetwork::RefererParser::path(request.referer)

    if referer_path == '/admin/products/bulk_edit'
      bulk_edit_admin_products_url
    else
      location_after_save_without_bulk_edit
    end
  end
  alias_method_chain :location_after_save, :bulk_edit

  def collection
    # This method is copied directly from the spree product controller, except where we narrow the search below with the managed_by search to support
    # enterprise users.
    # TODO: There has to be a better way!!!
    return @collection if @collection.present?
    params[:q] ||= {}
    params[:q][:deleted_at_null] ||= "1"

    params[:q][:s] ||= "name asc"

    @search = Spree::Product.ransack(params[:q]) # this line is modified - hit Spree::Product instead of super, avoiding cancan error for fetching records with block permissions via accessible_by
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

  def collection_actions
    [:index, :bulk_edit, :bulk_update]
  end


  private

  def load_form_data
    @producers = OpenFoodNetwork::Permissions.new(spree_current_user).managed_product_enterprises.is_primary_producer.by_name
    @taxons = Spree::Taxon.order(:name)
  end

  def strip_new_properties
    unless spree_current_user.admin? || params[:product][:product_properties_attributes].nil?
      names = Spree::Property.pluck(:name)
      params[:product][:product_properties_attributes].each do |key, property|
        params[:product][:product_properties_attributes].delete key unless names.include? property[:property_name]
      end
    end
  end
end
