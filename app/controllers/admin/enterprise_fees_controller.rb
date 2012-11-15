module Admin
  class EnterpriseFeesController < ResourceController
    before_filter :load_enterprise_fees_set, :only => :index

    private
    def load_enterprise_fees_set
      @enterprise_fees_set = ModelSet.new EnterpriseFee.all, :collection => collection
    end
  end
end
