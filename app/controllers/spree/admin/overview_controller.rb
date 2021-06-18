# frozen_string_literal: true

# this clas was inspired (heavily) from the mephisto admin architecture
module Spree
  module Admin
    class OverviewController < Spree::Admin::BaseController
      def index
        @enterprises = Enterprise
          .managed_by(spree_current_user)
          .order('is_primary_producer ASC, name')
        @product_count = Spree::Product.active.managed_by(spree_current_user).count
        @order_cycle_count = OrderCycle.active.managed_by(spree_current_user).count

        if first_access
          redirect_to enterprises_path
        else
          render dashboard_view
        end
      end

      private

      # Checks whether the user is accessing the admin for the first time
      #
      # @return [Boolean]
      def first_access
        outside_referral && incomplete_enterprise_registration?
      end

      # Checks whether the request comes from another admin page or not
      #
      # @return [Boolean]
      def outside_referral
        !URI(request.referer.to_s).path.match(%r{/admin})
      end

      # Checks that all of the enterprises owned by the current user have a 'sells'
      # property specified, which indicates that the registration process has been
      # completed
      #
      # @return [Boolean]
      def incomplete_enterprise_registration?
        @incomplete_enterprise_registration ||= spree_current_user
          .owned_enterprises
          .where(sells: 'unspecified')
          .exists?
      end

      # Returns the appropriate enterprise path for the current user
      #
      # @return [String]
      def enterprises_path
        if managed_enterprises.size == 1
          @enterprise = @enterprises.first
          main_app.welcome_admin_enterprise_path(@enterprise)
        else
          main_app.admin_enterprises_path
        end
      end

      # Returns the appropriate dashboard view for the current user
      #
      # @return [String]
      def dashboard_view
        if managed_enterprises.size == 1
          @enterprise = @enterprises.first
          :single_enterprise_dashboard
        else
          :multi_enterprise_dashboard
        end
      end

      # Returns the list of enterprises the current user is manager of
      #
      # @return [ActiveRecord::Relation<Enterprise>]
      def managed_enterprises
        spree_current_user.enterprises
      end
    end
  end
end
