module Spree
  Payment.class_eval do
    has_one :adjustment, as: :source, dependent: :destroy

    after_save :ensure_correct_adjustment, :update_order

    attr_accessible :source

    def ensure_correct_adjustment
      # Don't charge for invalid payments.
      # PayPalExpress always creates a payment that is invalidated later.
      # Unknown: What about failed payments?
      if state == "invalid"
        adjustment.andand.destroy
      elsif adjustment
        adjustment.originator = payment_method
        adjustment.label = adjustment_label
        adjustment.save
      else
        payment_method.create_adjustment(adjustment_label, order, self, true)
        association(:adjustment).reload
      end
    end

    def adjustment_label
      I18n.t('payment_method_fee')
    end

    # This is called by the calculator of a payment method
    def line_items
      if order.complete? && Spree::Config[:track_inventory_levels]
        order.line_items.select { |li| inventory_units.pluck(:variant_id).include?(li.variant_id) }
      else
        order.line_items
      end
    end

    # Pin payments lacks void and credit methods, but it does have refund
    # Here we swap credit out for refund and remove void as a possible action
    def actions_with_pin_payment_adaptations
      actions = actions_without_pin_payment_adaptations
      if payment_method.is_a? Gateway::Pin
        actions << 'refund' if actions.include? 'credit'
        actions.reject! { |a| ['credit', 'void'].include? a }
      end
      actions
    end
    alias_method_chain :actions, :pin_payment_adaptations


    def refund!(refund_amount=nil)
      protect_from_connection_error do
        check_environment

        refund_amount = calculate_refund_amount(refund_amount)

        if payment_method.payment_profiles_supported?
          response = payment_method.refund((refund_amount * 100).round, source, response_code, gateway_options)
        else
          response = payment_method.refund((refund_amount * 100).round, response_code, gateway_options)
        end

        record_response(response)

        if response.success?
          self.class.create({ :order => order,
                              :source => self,
                              :payment_method => payment_method,
                              :amount => refund_amount.abs * -1,
                              :response_code => response.authorization,
                              :state => 'completed' }, :without_protection => true)
        else
          gateway_error(response)
        end
      end
    end

    # Import from future Spree
    def build_source
      return if source_attributes.nil?
      if payment_method and payment_method.payment_source_class
        self.source = payment_method.payment_source_class.new(source_attributes)
        self.source.payment_method_id = payment_method.id
        self.source.user_id = self.order.user_id if self.order
      end
    end

    private

    def calculate_refund_amount(refund_amount=nil)
      refund_amount ||= credit_allowed >= order.outstanding_balance.abs ? order.outstanding_balance.abs : credit_allowed.abs
      refund_amount.to_f
    end

    def create_payment_profile
      return unless source.is_a?(CreditCard) &&
        (source.number || source.gateway_payment_profile_id) &&
          source.gateway_customer_profile_id.nil?
      payment_method.create_profile(self)
    rescue ActiveMerchant::ConnectionError => e
      gateway_error e
    end

  end
end
