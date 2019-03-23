module AbilityHelper
  shared_examples "allows access to Enterprise Fee Summary only if feature flag enabled" do
    it "should not be able to read Enterprise Fee Summary" do
      is_expected.not_to have_link_to_enterprise_fee_summary
      is_expected.not_to have_direct_access_to_enterprise_fee_summary
    end

    context "when feature flag for Enterprise Fee Summary is enabled absolutely" do
      before do
        feature_flags = instance_double(FeatureFlags, enterprise_fee_summary_enabled?: true)
        allow(FeatureFlags).to receive(:new).with(user) { feature_flags }
      end

      it "should be able to see link and read report" do
        is_expected.to have_link_to_enterprise_fee_summary
        is_expected.to have_direct_access_to_enterprise_fee_summary
      end
    end

    def have_link_to_enterprise_fee_summary
      have_ability([:enterprise_fee_summary], for: Spree::Admin::ReportsController)
    end

    def have_direct_access_to_enterprise_fee_summary
      have_ability([:admin, :new, :create], for: :enterprise_fee_summary)
    end
  end
end
