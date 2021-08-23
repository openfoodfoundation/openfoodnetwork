# frozen_string_literal: true

module AbilityHelper
  shared_examples "allows access to Enterprise Fee Summary" do
    it "should be able to see link and read report" do
      is_expected.to have_link_to_enterprise_fee_summary
      is_expected.to have_direct_access_to_enterprise_fee_summary
    end

    def have_link_to_enterprise_fee_summary
      have_ability([:enterprise_fee_summary], for: Spree::Admin::ReportsController)
    end

    def have_direct_access_to_enterprise_fee_summary
      have_ability([:admin, :new, :create], for: :enterprise_fee_summary)
    end
  end
end
