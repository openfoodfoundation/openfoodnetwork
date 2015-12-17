require 'spec_helper'

describe Admin::BusinessModelConfigurationHelper do
  describe "describing monthly bills for enterprises" do
    context "when tax is applied to the service change" do
      before { Spree::Config.set(:account_invoices_tax_rate, 0.1) }
      context "when a fixed cost is included" do
        before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

        context "when a percentage of turnover is included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "$10 + 5.0% OF SALES{joiner}CAPPED AT $20 PER MONTH, PLUS GST" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "$10 + 5.0% OF SALES PER MONTH, PLUS GST" }
          end
        end

        context "when a percentage of turnover is not included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "$10 PER MONTH, PLUS GST" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "$10 PER MONTH, PLUS GST" }
          end
        end
      end

      context "when a fixed cost is not included" do
        before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

        context "when a percentage of turnover is included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES{joiner}CAPPED AT $20 PER MONTH, PLUS GST" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES PER MONTH, PLUS GST" }
          end
        end

        context "when a percentage of turnover is not included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "FREE" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "FREE" }
          end
        end
      end
    end

    context "when tax is applied to the service change" do
      before { Spree::Config.set(:account_invoices_tax_rate, 0.0) }
      context "when a fixed cost is included" do
        before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

        context "when a percentage of turnover is included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "$10 + 5.0% OF SALES{joiner}CAPPED AT $20 PER MONTH" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "$10 + 5.0% OF SALES PER MONTH" }
          end
        end

        context "when a percentage of turnover is not included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "$10 PER MONTH" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "$10 PER MONTH" }
          end
        end
      end

      context "when a fixed cost is not included" do
        before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

        context "when a percentage of turnover is included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES{joiner}CAPPED AT $20 PER MONTH" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES PER MONTH" }
          end
        end

        context "when a percentage of turnover is not included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(helper.monthly_bill_description).to eq "FREE" }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(helper.monthly_bill_description).to eq "FREE" }
          end
        end
      end
    end
  end
end
