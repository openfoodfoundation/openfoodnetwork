# frozen_string_literal: true

module Admin
  class ProducerPropertiesController < Admin::ResourceController
    before_action :load_enterprise
    before_action :load_properties
    before_action :setup_property, only: [:index]

    private

    def collection_url
      main_app.admin_enterprise_producer_properties_url(@enterprise)
    end

    def load_enterprise
      @enterprise = Enterprise.find_by! permalink: params[:enterprise_id]
    end

    def load_properties
      @properties = Spree::Property.pluck(:name)
    end

    def setup_property
      @enterprise.producer_properties.build
    end
  end
end
