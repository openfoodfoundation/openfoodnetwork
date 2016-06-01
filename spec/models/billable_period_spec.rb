require 'spec_helper'

describe BillablePeriod, type: :model do

  require 'spec_helper'

  describe 'ensure_correct_adjustment' do
    let!(:start_of_july) { Time.zone.now.beginning_of_year + 6.months }
    let!(:user) { create(:user) }
    let!(:invoice) { create(:order, user: user) }
    let!(:subject) { create(:billable_period, owner: user, begins_at: start_of_july, ends_at: start_of_july + 12.days) }

    before do
      allow(subject).to receive(:bill) { 99 }
      allow(subject).to receive(:adjustment_label) { "Label for adjustment" }
      Spree::Config.set({ account_invoices_tax_rate: 0.1 })
    end

    context "when no adjustment currently exists" do
      it "creates an adjustment on the given order" do
        expect(invoice.total_tax).to eq 0.0
        expect(subject.adjustment).to be nil
        subject.ensure_correct_adjustment_for(invoice)
        expect(subject.adjustment).to be_a Spree::Adjustment
        expect(invoice.total_tax).to eq 9.0
      end
    end
  end

  describe "calculating monthly bills for enterprises with no turnover" do
    let!(:subject) { create(:billable_period, turnover: 0) }

    context "when no tax is charged" do
      before { Spree::Config.set(:account_invoices_tax_rate, 0) }

      context "when minimum billable turnover is zero" do
        before { Spree::Config.set(:minimum_billable_turnover, 0) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }
          it { expect(subject.bill).to eq 10 }
        end

        context "when no fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }
          it { expect(subject.bill).to eq 0 }
        end
      end

      context "when minimum billable turnover is > zero" do
        before { Spree::Config.set(:minimum_billable_turnover, 1) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }
          it { expect(subject.bill).to eq 0 }
        end

        context "when no fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }
          it { expect(subject.bill).to eq 0 }
        end
      end
    end

    context "when tax is charged" do
      before { Spree::Config.set(:account_invoices_tax_rate, 0.1) }

      context "when minimum billable turnover is zero" do
        before { Spree::Config.set(:minimum_billable_turnover, 0) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }
          it { expect(subject.bill).to eq 11 }
        end

        context "when no fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }
          it { expect(subject.bill).to eq 0 }
        end
      end

      context "when minimum billable turnover is > zero" do
        before { Spree::Config.set(:minimum_billable_turnover, 1) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }
          it { expect(subject.bill).to eq 0 }
        end

        context "when no fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }
          it { expect(subject.bill).to eq 0 }
        end
      end
    end
  end

  describe "calculating monthly bills for enterprises" do
    let!(:subject) { create(:billable_period, turnover: 100) }

    context "when no tax is charged" do
      before { Spree::Config.set(:account_invoices_tax_rate, 0) }

      context "when no minimum billable turnover" do
        before { Spree::Config.set(:minimum_billable_turnover, 0) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

          context "when a percentage of turnover is included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

            context "when the bill is capped" do
              context "at a level higher than the fixed charge plus the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 65) }
                it { expect(subject.bill).to eq 60 }
              end

              context "at a level lower than the fixed charge plus the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 55) }
                it { expect(subject.bill).to eq 55 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 60 }
            end
          end

          context "when a percentage of turnover is not included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

            context "when the bill is capped" do
              context "at a level higher than the fixed charge" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 15) }
                it { expect(subject.bill).to eq 10 }
              end

              context "at a level lower than the fixed charge" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 5) }
                it { expect(subject.bill).to eq 5 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 10 }
            end
          end
        end

        context "when a fixed cost is not included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

          context "when a percentage of turnover is included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

            context "when the bill is capped" do
              context "at a level higher than the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 55) }
                it { expect(subject.bill).to eq 50 }
              end

              context "at a level lower than the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 45) }
                it { expect(subject.bill).to eq 45 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 50 }
            end
          end

          context "when a percentage of turnover is not included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

            context "when the bill is capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
              it { expect(subject.bill).to eq 0 }
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 0 }
            end
          end
        end
      end

      context "when turnover is above minimum billable turnover" do
        before { Spree::Config.set(:minimum_billable_turnover, 99) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

          context "when a percentage of turnover is included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

            context "when the bill is capped" do
              context "at a level higher than the fixed charge plus the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 65) }
                it { expect(subject.bill).to eq 60 }
              end

              context "at a level lower than the fixed charge plus the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 55) }
                it { expect(subject.bill).to eq 55 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 60 }
            end
          end

          context "when a percentage of turnover is not included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

            context "when the bill is capped" do
              context "at a level higher than the fixed charge" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 15) }
                it { expect(subject.bill).to eq 10 }
              end

              context "at a level lower than the fixed charge" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 5) }
                it { expect(subject.bill).to eq 5 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 10 }
            end
          end
        end

        context "when a fixed cost is not included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

          context "when a percentage of turnover is included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

            context "when the bill is capped" do
              context "at a level higher than the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 55) }
                it { expect(subject.bill).to eq 50 }
              end

              context "at a level lower than the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 45) }
                it { expect(subject.bill).to eq 45 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 50 }
            end
          end

          context "when a percentage of turnover is not included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

            context "when the bill is capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
              it { expect(subject.bill).to eq 0 }
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 0 }
            end
          end
        end
      end

      context "when turnover is below minimum billable turnover" do
        before { Spree::Config.set(:minimum_billable_turnover, 101) }

        context "when a fixed cost is included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

          context "when a percentage of turnover is included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

            context "when the bill is capped" do
              context "at a level higher than the fixed charge plus the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 65) }
                it { expect(subject.bill).to eq 0 }
              end

              context "at a level lower than the fixed charge plus the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 55) }
                it { expect(subject.bill).to eq 0 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 0 }
            end
          end

          context "when a percentage of turnover is not included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

            context "when the bill is capped" do
              context "at a level higher than the fixed charge" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 15) }
                it { expect(subject.bill).to eq 0 }
              end

              context "at a level lower than the fixed charge" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 5) }
                it { expect(subject.bill).to eq 0 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 0 }
            end
          end
        end

        context "when a fixed cost is not included" do
          before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

          context "when a percentage of turnover is included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

            context "when the bill is capped" do
              context "at a level higher than the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 55) }
                it { expect(subject.bill).to eq 0 }
              end

              context "at a level lower than the product of the rate and turnover" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 45) }
                it { expect(subject.bill).to eq 0 }
              end
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 0 }
            end
          end

          context "when a percentage of turnover is not included" do
            before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

            context "when the bill is capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
              it { expect(subject.bill).to eq 0 }
            end

            context "when the bill is not capped" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
              it { expect(subject.bill).to eq 0 }
            end
          end
        end
      end

      context "when tax is charged" do
        before { Spree::Config.set(:account_invoices_tax_rate, 0.1) }

        context "when turnover is above minimum billable turnover" do
          before { Spree::Config.set(:minimum_billable_turnover, 99) }

          context "when a fixed cost is included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

              context "when the bill is capped" do
                context "at a level higher than the fixed charge plus the product of the rate and turnover" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 61) }
                  it { expect(subject.bill).to eq 66 }
                end

                context "at a level lower than the fixed charge plus the product of the rate and turnover" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 59) }
                  it {
                    expect(subject.bill.to_f).to eq 64.9
                  }
                end
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(subject.bill).to eq 66 }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                context "at a level higher than the fixed charge" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 11) }
                  it { expect(subject.bill).to eq 11 }
                end

                context "at a level lower than the fixed charge" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 9) }
                  it { expect(subject.bill.to_f).to eq 9.9 }
                end
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(subject.bill).to eq 11 }
              end
            end
          end

          context "when a fixed cost is not included" do
            before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

            context "when a percentage of turnover is included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

              context "when the bill is capped" do
                context "at a level higher than the product of the rate and turnover" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 51) }
                  it { expect(subject.bill).to eq 55 }
                end

                context "at a level lower than the product of the rate and turnover" do
                  before { Spree::Config.set(:account_invoices_monthly_cap, 49) }
                  it { expect(subject.bill.to_f).to eq 53.9 }
                end
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(subject.bill).to eq 55 }
              end
            end

            context "when a percentage of turnover is not included" do
              before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

              context "when the bill is capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
                it { expect(subject.bill).to eq 0 }
              end

              context "when the bill is not capped" do
                before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
                it { expect(subject.bill).to eq 0 }
              end
            end
          end
        end
      end
    end

    context "when turnover is below minimum billable turnover" do
      before { Spree::Config.set(:minimum_billable_turnover, 101) }

      context "when a fixed cost is included" do
        before { Spree::Config.set(:account_invoices_monthly_fixed, 10) }

        context "when a percentage of turnover is included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

          context "when the bill is capped" do
            context "at a level higher than the fixed charge plus the product of the rate and turnover" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 61) }
              it { expect(subject.bill).to eq 0 }
            end

            context "at a level lower than the fixed charge plus the product of the rate and turnover" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 59) }
              it {
                expect(subject.bill.to_f).to eq 0
              }
            end
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(subject.bill).to eq 0 }
          end
        end

        context "when a percentage of turnover is not included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

          context "when the bill is capped" do
            context "at a level higher than the fixed charge" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 11) }
              it { expect(subject.bill).to eq 0 }
            end

            context "at a level lower than the fixed charge" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 9) }
              it { expect(subject.bill.to_f).to eq 0 }
            end
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(subject.bill).to eq 0 }
          end
        end
      end

      context "when a fixed cost is not included" do
        before { Spree::Config.set(:account_invoices_monthly_fixed, 0) }

        context "when a percentage of turnover is included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0.5) }

          context "when the bill is capped" do
            context "at a level higher than the product of the rate and turnover" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 51) }
              it { expect(subject.bill).to eq 0 }
            end

            context "at a level lower than the product of the rate and turnover" do
              before { Spree::Config.set(:account_invoices_monthly_cap, 49) }
              it { expect(subject.bill.to_f).to eq 0 }
            end
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(subject.bill).to eq 0 }
          end
        end

        context "when a percentage of turnover is not included" do
          before { Spree::Config.set(:account_invoices_monthly_rate, 0) }

          context "when the bill is capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 20) }
            it { expect(subject.bill).to eq 0 }
          end

          context "when the bill is not capped" do
            before { Spree::Config.set(:account_invoices_monthly_cap, 0) }
            it { expect(subject.bill).to eq 0 }
          end
        end
      end
    end
  end
end
