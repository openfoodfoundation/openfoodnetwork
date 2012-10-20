class SuppliersController < BaseController
  def index
    @suppliers = Supplier.all
  end

  def show
    options = {:supplier_id => params[:id]}
    options.merge(params.reject { |k,v| k == :id })

    @supplier = Supplier.find params[:id]

    @searcher = Spree::Config.searcher_class.new(options)
    @products = @searcher.retrieve_products
  end
end
