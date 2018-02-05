module Api
  module Admin
    class ProxyOrderSerializer < ActiveModel::Serializer
      attributes :id, :state, :edit_path, :number, :completed_at, :order_cycle_id, :total
      attributes :update_issues

      def total
        if object.total.present?
          object.total.to_money.to_s
        else
          object.standing_order.standing_line_items.sum(&:total_estimate)
        end
      end

      def update_issues
        options[:order_update_issues].andand[object.order_id] || []
      end

      def completed_at
        object.completed_at.blank? ? "" : object.completed_at.strftime("%F %T")
      end

      def edit_path
        edit_admin_proxy_order_path(object)
      end
    end
  end
end
