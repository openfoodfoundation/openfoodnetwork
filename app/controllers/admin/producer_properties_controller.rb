module Admin
  class ProducerPropertiesController < ResourceController
    before_filter :find_properties

    before_filter :setup_property, only: [:index]



    private

    def find_properties
      @properties = Spree::Property.pluck(:name)
    end

    def setup_property
      @enterprise = Enterprise.find params[:enterprise_id]
      @enterprise.producer_properties.build
    end
  end
end
