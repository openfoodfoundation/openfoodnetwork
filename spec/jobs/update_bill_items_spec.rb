require 'spec_helper'

describe UpdateBillItems do
  describe "smoke tests" do
    # Chose july to test with because June has 30 days and so is easy to calculate end date for shop trial
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    context "where the enterprise existed at the beginning of the current billing period", versioning: true do
      let!(:enterprise) { create(:supplier_enterprise, created_at: start_of_july - 2.months, sells: 'any') }

      let!(:order1) { create(:order, completed_at: start_of_july + 5.days, distributor: enterprise) }
      let!(:order2) { create(:order, completed_at: start_of_july + 15.days, distributor: enterprise) }
      let!(:order3) { create(:order, completed_at: start_of_july + 25.days, distributor: enterprise) }

      before do
        order1.line_items = [ create(:line_item, price: 12.56, order: order1) ]
        order2.line_items = [ create(:line_item, price: 87.44, order: order2) ]
        order3.line_items = [ create(:line_item, price: 50.00, order: order3) ]
        [order1, order2, order3].each(&:update!)
      end

      context "where the sells property of the enterprise has not been altered within the current billing period" do
        before do
          Timecop.travel(start_of_july + 28.days)
        end

        after do
          Timecop.return
        end

        context "where no trial information has been set" do
          before do
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "creates a single bill item" do
            expect(bill_items.count).to eq 1
            expect(bill_items.map(&:sells)).to eq ['any']
          end

          it "calculates turnover for the whole month to date" do
            expect(bill_items.first.turnover).to eq (order1.total + order2.total + order3.total)
          end
        end

        context "where a trial ended during the current billing period" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 10.days)
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'any']
            expect(bill_items.map(&:trial)).to eq [true, false]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total + order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where the trial began part-way through the current billing period" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 10.days)
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'any']
            expect(bill_items.map(&:trial)).to eq [false, true]
          end

          it "splits the turnover for the month to date" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.last.turnover).to eq order2.total + order3.total
          end
        end
      end

      context "where the sells property of the enterprise has been altered within the current billing period" do
        before do
          Timecop.travel(start_of_july + 10.days) do
            # NOTE: Sells is changed between when order1 and order2 are placed
            enterprise.update_attribute(:sells, 'own')
          end

          Timecop.travel(start_of_july + 28.days)
        end

        after do
          Timecop.return
        end

        context "where no trial information has been set" do
          before do
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits the billing period into a separate item for each sells value" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'own']
          end

          it "splits the turnover for the month to date" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.last.turnover).to eq order2.total + order3.total
          end
        end

        context "where a trial ended during the current billing period, after sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 10.days)
            Timecop.travel(start_of_july + 10.days) do
              # NOTE: Sells is changed between when order1 and order2 are placed
              enterprise.update_attribute(:sells, 'own')
            end
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'own', 'own']
            expect(bill_items.map(&:trial)).to eq [true, true, false]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where a trial ended during the current billing period, before sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 22.days)
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'own']
            expect(bill_items.map(&:trial)).to eq [true, false, false]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq 0
            expect(bill_items.last.turnover).to eq (order2.total + order3.total)
          end
        end

        context "where the trial began part-way through the current billing period, after sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 18.days)
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'own', 'own']
            expect(bill_items.map(&:trial)).to eq [false, false, true]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where the trial began part-way through the current billing period, before sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 8.days)
            UpdateBillItems.new('lala').perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'own']
            expect(bill_items.map(&:trial)).to eq [false, true, true]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq 0
            expect(bill_items.last.turnover).to eq (order2.total + order3.total)
          end
        end
      end
    end

    context "where the enterprise was created after the beginning of the current billing period" do

    end
  end


end
