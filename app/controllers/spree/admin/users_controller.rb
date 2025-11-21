# frozen_string_literal: true

module Spree
  module Admin
    class UsersController < ::Admin::ResourceController
      helper I18nHelper

      rescue_from Spree::User::DestroyWithOrdersError, with: :user_destroy_with_orders_error

      after_action :sign_in_if_change_own_password, only: :update

      # http://spreecommerce.com/blog/2010/11/02/json-hijacking-vulnerability/
      before_action :check_json_authenticity, only: :index

      def index
        respond_with(@collection) do |format|
          format.html
          format.json { render json: json_data }
        end
      end

      def create
        @user = Spree::User.new(user_params)
        if @user.save

          flash[:success] = flash_message_for(@user, :successfully_created)
          redirect_to edit_admin_user_path(@user)
        else
          render :new
        end
      end

      def update
        if @user.update(user_params)
          flash[:success] = update_message
          redirect_to edit_admin_user_path(@user)
        else
          render :edit
        end
      end

      protected

      def collection
        return @collection if @collection.present?

        if request.xhr? && params[:q].present?
          @collection = Spree::User.
            includes(:bill_address, :ship_address).
            where("spree_users.email #{LIKE} :search
                    OR (spree_addresses.firstname #{LIKE} :search
                      AND spree_addresses.id = spree_users.bill_address_id)
                    OR (spree_addresses.lastname  #{LIKE} :search
                      AND spree_addresses.id = spree_users.bill_address_id)
                    OR (spree_addresses.firstname #{LIKE} :search
                      AND spree_addresses.id = spree_users.ship_address_id)
                    OR (spree_addresses.lastname  #{LIKE} :search
                      AND spree_addresses.id = spree_users.ship_address_id)",
                  search: "#{params[:q].strip}%").
            limit(params[:limit] || 100)
        else
          @search = Spree::User.ransack(params[:q])
          @pagy, @collection = pagy(@search.result, limit: Spree::Config[:admin_products_per_page])
          @collection
        end
      end

      private

      def update_message
        return Spree.t(:show_api_key_view_toggled) if @user.show_api_key_view_previously_changed?

        if new_email_unconfirmed?
          Spree.t(:email_updated)
        else
          Spree.t(:account_updated)
        end
      end

      # handling raise from Admin::ResourceController#destroy
      def user_destroy_with_orders_error
        render status: :forbidden, text: Spree.t(:error_user_destroy_with_orders)
      end

      # Allow different formats of json data to suit different ajax calls
      def json_data
        json_format = params[:json_format] || 'default'
        case json_format
        when 'basic'
          collection.map { |u| { 'id' => u.id, 'name' => u.email } }.to_json
        else
          address_fields = [:firstname, :lastname, :address1, :address2, :city,
                            :zipcode, :phone, :state_name, :state_id, :country_id]
          includes = { only: address_fields, include: { state: { only: :name },
                                                        country: { only: :name } } }

          collection.to_json(only: [:id, :email], include:
                             { bill_address: includes, ship_address: includes })
        end
      end

      def sign_in_if_change_own_password
        return unless spree_current_user == @user && @user.password.present?

        sign_in(@user, event: :authentication, bypass: true)
      end

      def new_email_unconfirmed?
        params[:user][:email] != @user.email
      end

      def build_resource
        model_class.new(locale: I18n.default_locale)
      end

      def user_params
        ::PermittedAttributes::User.new(params).call(
          %i[admin enterprise_limit show_api_key_view]
        )
      end
    end
  end
end
