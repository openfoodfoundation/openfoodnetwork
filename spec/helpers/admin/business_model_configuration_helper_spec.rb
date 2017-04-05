require 'spec_helper'

describe Admin::BusinessModelConfigurationHelper, type: :helper do
  describe "describing monthly bills for enterprises" do

    context "when there is no free trial" do
      before { Spree::Config.set(:shop_trial_length_days, 0) }

      context "when tax is applied to the service change" do
        before { Spree::Config.set(:account_invoices_tax_rate, 0.1) }

        context "when minimum billable turnover is zero" do
          before { Spree::Config.set(:minimum_billable_turnover, 0) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES PER MONTH, PLUS GST" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
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

        context "when minimum billable turnover is 100" do
          before { Spree::Config.set(:minimum_billable_turnover, 100) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH, PLUS GST" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

              context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

                context "when the bill is capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                  it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
                end

                context "when the bill is not capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                  it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH, PLUS GST" }
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

      context "when tax is not applied to the service change" do
        before { Spree::Config.set(:account_invoices_tax_rate, 0.0) }

        context "when minimum billable turnover is zero" do
          before { Spree::Config.set(:minimum_billable_turnover, 0) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES PER MONTH" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
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

        context "when minimum billable turnover is 100" do
          before { Spree::Config.set(:minimum_billable_turnover, 100) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "#{with_currency(10, no_cents: true)} PER MONTH" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

              context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

                context "when the bill is capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                  it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
                end

                context "when the bill is not capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                  it { expect(helper.monthly_bill_description).to eq "5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH" }
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

    context "when there is a 30 day free trial" do
      before { Spree::Config.set(:shop_trial_length_days, 30) }

      context "when tax is applied to the service change" do
        before { Spree::Config.set(:account_invoices_tax_rate, 0.1) }

        context "when minimum billable turnover is zero" do
          before { Spree::Config.set(:minimum_billable_turnover, 0) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES PER MONTH, PLUS GST" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES PER MONTH, PLUS GST" }
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

        context "when minimum billable turnover is 100" do
          before { Spree::Config.set(:minimum_billable_turnover, 100) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH, PLUS GST" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH, PLUS GST" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

              context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

                context "when the bill is capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                  it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH, PLUS GST" }
                end

                context "when the bill is not capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                  it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH, PLUS GST" }
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

      context "when tax is not applied to the service change" do
        before { Spree::Config.set(:account_invoices_tax_rate, 0.0) }

        context "when minimum billable turnover is zero" do
          before { Spree::Config.set(:minimum_billable_turnover, 0) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES PER MONTH" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES PER MONTH" }
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

        context "when minimum billable turnover is 100" do
          before { Spree::Config.set(:minimum_billable_turnover, 100) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} + 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH" }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH" }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN #{with_currency(10, no_cents: true)} PER MONTH" }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

              context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.05) }

                context "when the bill is capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                  it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)}, CAPPED AT #{with_currency(20, no_cents: true)} PER MONTH" }
                end

                context "when the bill is not capped" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                  it { expect(helper.monthly_bill_description).to eq "FREE TRIAL THEN 5.0% OF SALES ONCE TURNOVER EXCEEDS #{with_currency(100, no_cents: true)} PER MONTH" }
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
  end
end
