Spree::Core::Engine.config.to_prepare do
  if Spree.user_class
    Spree.user_class.class_eval do

      # Override of spree method to ignore orders associated with account_invoices
      def last_incomplete_spree_order
        spree_orders.incomplete.where("id NOT IN (?)", account_invoices.map(&:order_id)).order('created_at DESC').first
      end
    end
  end
end
