module Admin
  class ProducerPropertiesController < ResourceController
    before_filter :load_enterprise
    before_filter :load_properties
    before_filter :setup_property, only: [:index]


    private

    def collection_url
      main_app.admin_enterprise_producer_properties_url(@enterprise)
    end

    def load_enterprise
      @enterprise = Enterprise.find_by_permalink! params[:enterprise_id]
    end

    def load_properties
      @properties = Spree::Property.pluck(:name)
    end

    def setup_property
      @enterprise.producer_properties.build
    end
  end
end
