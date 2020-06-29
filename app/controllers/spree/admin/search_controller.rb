module Spree
  module Admin
    class SearchController < Spree::Admin::BaseController
      # http://spreecommerce.com/blog/2010/11/02/json-hijacking-vulnerability/
      before_action :check_json_authenticity, only: :index
      respond_to :json

      def known_users
        @users = if exact_match = Spree.user_class.find_by(email: params[:q])
                   [exact_match]
                 else
                   spree_current_user.known_users.ransack(ransack_hash).result.limit(10)
                 end

        render json: @users, each_serializer: ::Api::Admin::UserSerializer
      end

      def customers
        @customers = []
        if spree_current_user.enterprises.pluck(:id).include? params[:distributor_id].to_i
          @customers = Customer.
            ransack(m: 'or', email_start: params[:q], name_start: params[:q]).
            result.
            where(enterprise_id: params[:distributor_id])
        end
        render json: @customers, each_serializer: ::Api::Admin::CustomerSerializer
      end

      private

      def ransack_hash
        {
          m: 'or',
          email_start: params[:q],
          ship_address_firstname_start: params[:q],
          ship_address_lastname_start: params[:q],
          bill_address_firstname_start: params[:q],
          bill_address_lastname_start: params[:q]
        }
      end
    end
  end
end
