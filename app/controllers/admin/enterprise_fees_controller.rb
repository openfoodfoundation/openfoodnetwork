module Admin
  class EnterpriseFeesController < ResourceController
    before_filter :load_enterprise_fees_set, :only => :index
    before_filter :load_data

    private
    def load_enterprise_fees_set
      @enterprise_fees_set = ModelSet.new EnterpriseFee.all, :collection => collection
    end

    def load_data
      @calculators = EnterpriseFee.calculators.sort_by(&:name)
    end

  end
end
