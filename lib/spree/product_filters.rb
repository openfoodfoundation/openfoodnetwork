module Spree
  module ProductFilters
    if Distributor.table_exists?
      Spree::Product.scope :distributor_any,
        lambda {|*opts|
          conds = opts.map {|o| ProductFilters.distributor_filter[:conds][o]}.reject {|c| c.nil?}
          Spree::Product.joins(:distributors).conditions_any(conds)
        }

      def ProductFilters.distributor_filter
        distributors = Distributor.all.map(&:name).compact.uniq
        conds  = Hash[*distributors.map { |d| [d, "#{Distributor.table_name}.name = '#{d}'"] }.flatten]
        { :name   => "Group",
          :scope  => :distributor_any,
          :conds  => conds,
          :labels => (distributors.sort).map { |k| [k, k] }
        }
      end
    end
  end
end
