module Admin
  class SuppliersController < ResourceController
    before_filter :load_data, :except => [:index]

    helper 'spree/products'

    private
    def load_data
      @countries = Spree::Country.order(:name)
    end

    def collection
      super.order(:name)
    end
  end
end
