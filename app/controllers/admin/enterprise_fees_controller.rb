module Admin
  class EnterpriseFeesController < ResourceController
    before_filter :load_enterprise_fee_set, :only => :index
    before_filter :load_data

    def index
      respond_to do |format|
        format.html
        format.json { @presented_collection = @collection.each_with_index.map { |ef, i| EnterpriseFeePresenter.new(self, ef, i) } }
      end
    end

    def bulk_update
      @enterprise_fee_set = EnterpriseFeeSet.new(params[:enterprise_fee_set])
      if @enterprise_fee_set.save
        redirect_to main_app.admin_enterprise_fees_path, :notice => 'Your enterprise fees have been updated.'
      else
        render :index
      end
    end


    private
    def load_enterprise_fee_set
      @enterprise_fee_set = EnterpriseFeeSet.new :collection => collection
    end

    def load_data
      @calculators = EnterpriseFee.calculators.sort_by(&:name)
    end

    def collection
      super + (1..3).map { EnterpriseFee.new }
    end

  end
end
