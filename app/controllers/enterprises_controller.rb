include Spree::ProductsHelper
class EnterprisesController < BaseController
  
  def index
    @enterprises = Enterprise.all
  end

  def suppliers
    @suppliers = Enterprise.is_primary_producer
  end

  def distributors
    @distributors = Enterprise.is_distributor

    respond_to do |format|
      format.js do
        @distributor_details = Hash[@distributors.map { |d| [d.id, render_to_string(:partial => 'enterprises/distributor_details', :locals => {:distributor => d})] }]
      end
      format.html do
        @distributors
      end
    end
  end

  def show
    options = {:enterprise_id => params[:id]}
    options.merge(params.reject { |k,v| k == :id })

    @enterprise = Enterprise.find params[:id]

    @searcher = Spree::Config.searcher_class.new(options)
    @products = @searcher.retrieve_products
  end

  # essentially the new 'show' action that renders non-spree view
  # will need to be renamed into show once the old one is removed
  def shop_front
    options = {:enterprise_id => params[:id]}
    options.merge(params.reject { |k,v| k == :id })

    @enterprise = Enterprise.find params[:id]

    @searcher = Spree::Config.searcher_class.new(options)
    @products = @searcher.retrieve_products
    render :layout => "landing_page"
  end

  def search
    @suburb = Suburb.find(params[:suburb_id]) if params[:suburb_id].present?
    @enterprises = Enterprise.find_near(@suburb)
    @enterprises_json = @enterprises.to_gmaps4rails
    render :layout => "landing_page"
  end
end
