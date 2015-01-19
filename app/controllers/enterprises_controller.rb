class EnterprisesController < BaseController
  layout "darkswarm"
  helper Spree::ProductsHelper
  include OrderCyclesHelper
  before_filter :set_order_cycles, only: :shop
  before_filter :load_active_distributors, only: :shop
  before_filter :clean_permalink, only: :check_permalink

  respond_to :js, only: :permalink_checker

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
    @enterprise = Enterprise.find_by_permalink(params[:id]) || Enterprise.find(params[:id])

    # User can view this page if they've already chosen their distributor, or if this page
    # is for a supplier, they may use it to select a distributor that sells this supplier's
    # products.
    unless current_distributor || @enterprise.is_primary_producer
      redirect_to spree.root_path and return
    end


    options = {:enterprise_id => params[:id]}
    options.merge(params.reject { |k,v| k == :id })

    @products = []

    if @enterprise.is_primary_producer
      @distributors = Enterprise.distributing_any_product_of(@enterprise.supplied_products).by_name.all
    end

    if current_order_cycle
      @searcher = Spree::Config.searcher_class.new(options)
      @products = @searcher.retrieve_products

      order_cycle_products = current_order_cycle.products_distributed_by(current_distributor)
      @products = @products & order_cycle_products
    end
  end

  def shop
    distributor = Enterprise.is_distributor.find_by_permalink(params[:id]) || Enterprise.is_distributor.find(params[:id])
    order = current_order(true)

    if order.distributor and order.distributor != distributor
      order.empty!
      order.set_order_cycle! nil
    end

    order.distributor = distributor

    order_cycle_options = OrderCycle.active.with_distributor(distributor)
    order.order_cycle = order_cycle_options.first if order_cycle_options.count == 1
    order.save!
  end

  def check_permalink
    return render text: params[:permalink], status: 409 if Enterprise.find_by_permalink params[:permalink]

    path = Rails.application.routes.recognize_path( "/#{ params[:permalink].to_s }" )
    if path && path[:controller] == "cms_content"
      render text: params[:permalink], status: 200
    else
      render text: params[:permalink], status: 409
    end
  end

  private

  def clean_permalink
    params[:permalink] = params[:permalink].delete "^a-zA-Z1-9-_"
  end

  def set_order_cycles
    @order_cycles = OrderCycle.with_distributor(@distributor).active

    # And default to the only order cycle if there's only the one
    if @order_cycles.count == 1
      current_order(true).set_order_cycle! @order_cycles.first
    end
  end
end
