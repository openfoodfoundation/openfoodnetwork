module Admin
  class EnterpriseFeesController < ResourceController
    before_filter :load_enterprise_fee_set, :only => :index
    before_filter :load_data
    before_filter :do_not_destroy_referenced_fees, :only => :destroy


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

    def do_not_destroy_referenced_fees
      product_distribution = ProductDistribution.where(:enterprise_fee_id => @object).first
      if product_distribution
        p = product_distribution.product
        error = "That enterprise fee cannot be deleted as it is referenced by a product distribution: #{p.id} - #{p.name}."

        respond_with(@object) do |format|
          format.html do
            flash[:error] = error
            redirect_to collection_url
          end
          format.js { render text: error, status: 403 }
        end
      end
    end

    def load_enterprise_fee_set
      @enterprise_fee_set = EnterpriseFeeSet.new :collection => collection
    end

    def load_data
      @calculators = EnterpriseFee.calculators.sort_by(&:name)
    end

    def collection
      super.order('enterprise_id', 'fee_type', 'name')
    end
  end
end
