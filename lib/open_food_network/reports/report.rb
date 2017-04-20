require 'open_food_network/reports/row'
require 'open_food_network/reports/rule'

module OpenFoodNetwork::Reports
  class Report
    class_attribute :_header, :_columns, :_rules_head
    attr_reader :params

    def initialize(user = nil, params = {})
      @user = user
      @params = params
    end

    def search
      @search ||= permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
    end

    def table_items
      @orders = search.result

      # FIXME - Maybe we just need orders instead of line_items?
      @line_items = permissions.visible_line_items.merge(Spree::LineItem.where(order_id: @orders))
      @line_items = @line_items.preload([:order, :variant, :product])
      @line_items = @line_items.supplied_by_any(params[:q][:supplier_id_in]) if params[:q].andand[:supplier_id_in].present?

      # If empty array is passed in, the where clause will return all line_items, which is bad
      line_items_with_hidden_details =
        permissions.editable_line_items.empty? ? @line_items : @line_items.where('"spree_line_items"."id" NOT IN (?)', permissions.editable_line_items)

      @line_items.select{ |li| line_items_with_hidden_details.include? li }.each do |line_item|
        # TODO We should really be hiding customer code here too, but until we
        # have an actual association between order and customer, it's a bit tricky
        line_item.order.bill_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.ship_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.assign_attributes(email: "HIDDEN")
      end

      @line_items
    end

    def line_items
      @line_items ||= table_items
    end

    def orders
      @orders ||= Spree::Order.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_orders.*')
    end

    def variants
      @variants ||= Spree::Variant.joins(:line_items).where(spree_line_items: { id: line_items.pluck(:id) }).select('DISTINCT spree_variants.*')
    end

    def products
      @products ||= Spree::Product.joins(:all_variants).where(spree_variants: { id: variants.pluck(:id) }).select('DISTINCT spree_products.*')
    end

    def distributors
      @distributors ||= Enterprise.joins(:distributed_orders).where(spree_orders: { id: orders.pluck(:id) }).select('DISTINCT enterprises.*')
    end

    def line_items_serialized
      ActiveModel::ArraySerializer.new(line_items, each_serializer: Api::Admin::Reports::LineItemSerializer)
    end

    def orders_serialized
      ActiveModel::ArraySerializer.new(orders, each_serializer: Api::Admin::Reports::OrderSerializer)
    end

    def variants_serialized
      ActiveModel::ArraySerializer.new(variants, each_serializer: Api::Admin::Reports::VariantSerializer)
    end

    def products_serialized
      ActiveModel::ArraySerializer.new(products, each_serializer: Api::Admin::Reports::ProductSerializer)
    end

    def distributors_serialized
      ActiveModel::ArraySerializer.new(distributors, each_serializer: Api::Admin::Reports::EnterpriseSerializer)
    end

    # TODO - ditch this after backend generated reports are not needed anymore
    # -- API
    def header
      self._header
    end

    def columns
      self._columns.to_a
    end

    def rules
      # Flatten linked list and return as hashes
      rules = []

      rule = self._rules_head
      while rule
        rules << rule
        rule = rule.next
      end

      rules.map &:to_h
    end

    private
    def permissions
      @permissions ||= OpenFoodNetwork::Permissions.new(@user)
    end

    # -- DSL
    def self.header(*columns)
      self._header = columns
    end

    def self.columns(&block)
      self._columns = Row.new
      Blockenspiel.invoke block, self._columns
    end

    def self.organise(&block)
      self._rules_head = Rule.new
      Blockenspiel.invoke block, self._rules_head
    end
  end
end
