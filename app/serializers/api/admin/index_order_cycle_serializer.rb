require 'open_food_network/order_cycle_permissions'

module Api
  module Admin
    class IndexOrderCycleSerializer < ActiveModel::Serializer
      include OrderCyclesHelper

      attributes :id, :name, :orders_open_at, :orders_close_at, :status, :variant_count, :deletable
      attributes :coordinator, :producers, :shops, :viewing_as_coordinator
      attributes :edit_path, :clone_path, :delete_path

      has_many :schedules, serializer: Api::Admin::IdNameSerializer

      def deletable
        can_delete?(object)
      end

      def variant_count
        object.variants.count
      end

      def status
        order_cycle_status_class object
      end

      def orders_open_at
        object.orders_open_at.to_s
      end

      def orders_close_at
        object.orders_close_at.to_s
      end

      def viewing_as_coordinator
        Enterprise.managed_by(options[:current_user]).include? object.coordinator
      end

      def coordinator
        Api::Admin::IdNameSerializer.new(object.coordinator).serializable_hash
      end

      def producers
        producers = object.suppliers.merge(visible_enterprises)
        ActiveModel::ArraySerializer.new(producers, each_serializer: Api::Admin::IdNameSerializer)
      end

      def shops
        shops = object.distributors.merge(visible_enterprises)
        ActiveModel::ArraySerializer.new(shops, each_serializer: Api::Admin::IdNameSerializer)
      end

      def edit_path
        edit_admin_order_cycle_path(object)
      end

      def clone_path
        clone_admin_order_cycle_path(object)
      end

      def delete_path
        admin_order_cycle_path(object)
      end

      private

      def visible_enterprises
        @visible_enterprises ||= OpenFoodNetwork::OrderCyclePermissions.new(options[:current_user], object).visible_enterprises
      end
    end
  end
end
