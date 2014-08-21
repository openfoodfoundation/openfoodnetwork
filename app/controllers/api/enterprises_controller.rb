module Api
  class EnterprisesController < Spree::Api::BaseController
    respond_to :json

    def managed
      @enterprises = Enterprise.ransack(params[:q]).result.managed_by(current_api_user)
      render params[:template] || :bulk_index
    end

    def accessible
      @enterprises = Enterprise.ransack(params[:q]).result.accessible_by(current_api_user)
      render params[:template] || :bulk_index
    end

    def create
      #authorize! :create, Enterprise

      @enterprise = Enterprise.new(params[:enterprise])
      if @enterprise.save
        render text: '', :status => 201
      else
        invalid_resource!(@enterprise)
      end
    end
  end
end
