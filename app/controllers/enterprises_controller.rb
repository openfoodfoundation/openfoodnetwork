include Spree::ProductsHelper
include OrderCyclesHelper

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

    @products = []

    if current_order_cycle
      @searcher = Spree::Config.searcher_class.new(options)
      @products = @searcher.retrieve_products

      order_cycle_products = current_order_cycle.products
      @products.select! { |p| order_cycle_products.include? p }
    end
  end

  def shop
    distributor = Enterprise.is_distributor.find params[:id]
    order = current_order(true)

    if order.distributor and order.distributor != distributor
      order.empty!
      order.set_order_cycle! nil
    end

    order.distributor = distributor

    order_cycle_options = OrderCycle.active.with_distributor(distributor)
    order.order_cycle = order_cycle_options.first if order_cycle_options.count == 1

    order.save!

    redirect_to main_app.enterprise_path(distributor)
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
