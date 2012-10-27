class DistributorsController < BaseController
  def index
    @distributors = Distributor.all

    respond_to do |format|
      format.js do
        @distributor_details = Hash[@distributors.map { |d| [d.id, render_to_string(:partial => 'distributors/details', :locals => {:distributor => d})] }]
      end
    end
  end

  def show
    options = {:distributor_id => params[:id]}
    options.merge(params.reject { |k,v| k == :id })

    @distributor = Distributor.find params[:id]

    @searcher = Spree::Config.searcher_class.new(options)
    @products = @searcher.retrieve_products
  end

  def select
    distributor = Distributor.find params[:id]

    order = current_order(true)

    if order.can_change_distributor?
      order.distributor = distributor
      order.save!
    end

    redirect_to distributor
  end

  def deselect
    order = current_order(true)

    if order.can_change_distributor?
      order.distributor = nil
      order.save!
    end

    redirect_to root_path
  end
end
