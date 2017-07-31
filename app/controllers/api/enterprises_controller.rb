module Api
  class EnterprisesController < Spree::Api::BaseController

    before_filter :override_owner, only: [:create, :update]
    before_filter :check_type, only: :update
    before_filter :override_sells, only: [:create, :update]
    before_filter :override_visible, only: [:create, :update]
    respond_to :json

    def managed
      @enterprises = Enterprise.ransack(params[:q]).result.managed_by(current_api_user)
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
      @enterprise = Enterprise.find_by_permalink(params[:id]) || Enterprise.find(params[:id])
      authorize! :update, @enterprise

      if @enterprise.update_attributes(params[:enterprise])
        render text: @enterprise.id, :status => 200
      else
        invalid_resource!(@enterprise)
      end
    end

    def update_image
      @enterprise = Enterprise.find_by_permalink(params[:id]) || Enterprise.find(params[:id])
      authorize! :update, @enterprise

      if params[:logo] && @enterprise.update_attributes( { logo: params[:logo] } )
        render text: @enterprise.logo.url(:medium), :status => 200
      elsif params[:promo] && @enterprise.update_attributes( { promo_image: params[:promo] } )
        render text: @enterprise.promo_image.url(:medium), :status => 200
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

    def override_sells
      has_hub = current_api_user.owned_enterprises.is_hub.any?
      new_enterprise_is_producer = !!params[:enterprise][:is_primary_producer]

      params[:enterprise][:sells] = if has_hub && !new_enterprise_is_producer
                                      'any'
                                    else
                                      'unspecified'
                                    end
    end

    def override_visible
      params[:enterprise][:visible] = false
    end
  end
end
