module Api
  class EnterprisesController < Api::BaseController
    before_filter :override_owner, only: [:create, :update]
    before_filter :check_type, only: :update
    before_filter :override_sells, only: [:create, :update]
    before_filter :override_visible, only: [:create, :update]
    respond_to :json
    skip_authorization_check only: [:shopfront]

    def create
      authorize! :create, Enterprise

      # params[:user_ids] breaks the enterprise creation
      # We remove them from params and save them after creating the enterprise
      user_ids = params[:enterprise].delete(:user_ids)
      @enterprise = Enterprise.new(params[:enterprise])
      if @enterprise.save
        save_enterprise_users(user_ids)
        render text: @enterprise.id, status: :created
      else
        invalid_resource!(@enterprise)
      end
    end

    def update
      @enterprise = Enterprise.find_by(permalink: params[:id]) || Enterprise.find(params[:id])
      authorize! :update, @enterprise

      if @enterprise.update_attributes(params[:enterprise])
        render text: @enterprise.id, status: :ok
      else
        invalid_resource!(@enterprise)
      end
    end

    def update_image
      @enterprise = Enterprise.find_by(permalink: params[:id]) || Enterprise.find(params[:id])
      authorize! :update, @enterprise

      if params[:logo] && @enterprise.update_attributes( logo: params[:logo] )
        render text: @enterprise.logo.url(:medium), status: :ok
      elsif params[:promo] && @enterprise.update_attributes( promo_image: params[:promo] )
        render text: @enterprise.promo_image.url(:medium), status: :ok
      else
        invalid_resource!(@enterprise)
      end
    end

    def shopfront
      enterprise = Enterprise.find_by(id: params[:id])

      render text: Api::EnterpriseShopfrontSerializer.new(enterprise).to_json, status: :ok
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

    def save_enterprise_users(user_ids)
      user_ids.each do |user_id|
        next if @enterprise.user_ids.include? user_id.to_i

        @enterprise.users << Spree::User.find(user_id)
      end
    end
  end
end
