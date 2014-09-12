module Api
  class EnterprisesController < Spree::Api::BaseController

    before_filter :override_owner, only: [:create, :update]
    before_filter :check_type, only: :update
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
      authorize! :create, Enterprise

      @enterprise = Enterprise.new(params[:enterprise])
      if @enterprise.save
        render text: @enterprise.id, :status => 201
      else
        invalid_resource!(@enterprise)
      end
    end

    def update
      authorize! :update, Enterprise

      @enterprise = Enterprise.find(params[:id])
      if @enterprise.update_attributes(params[:enterprise])
        render text: @enterprise.id, :status => 200
      else
        invalid_resource!(@enterprise)
      end
    end

    private

    def override_owner
      params[:enterprise][:owner_id] = current_api_user.id
    end

    def check_type
      params[:enterprise].delete :type unless current_api_user.admin?
    end
  end
end
