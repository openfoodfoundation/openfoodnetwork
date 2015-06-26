require 'spec_helper'

def travel_to(time)
  around { |example| Timecop.travel(start_of_july + time) { example.run } }
end

describe UpdateBillItems do
  describe "unit tests" do
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:updater) { UpdateBillItems.new }

    describe "perform", versioning: true do
      let!(:enterprise) { create(:supplier_enterprise, created_at: start_of_july - 1.month, sells: 'any') }

      before do
        allow(Enterprise).to receive(:select) { [enterprise] }
      end

      context "on the first of the month" do
        travel_to(3.hours)

        it "processes the previous month" do
          expect(updater).to receive(:split_for_trial)
          .with(enterprise, start_of_july - 1.month, start_of_july, nil, nil)
          updater.perform
        end
      end

      context "on all other days" do
        travel_to(1.day + 3.hours)

        it "processes the current month up until previous midnight" do
          expect(updater).to receive(:split_for_trial)
          .with(enterprise, start_of_july, start_of_july + 1.day, nil, nil)
          updater.perform
        end
      end

      context "when an enterprise is created before the beginning of the current month" do
        travel_to(28.days)

        context "when no alterations to sells or owner have been made during the current month" do

          it "begins at the start of the month" do
            expect(updater).to receive(:split_for_trial)
            .with(enterprise, start_of_july, start_of_july + 28.days, nil, nil)
            updater.perform
          end
        end

        context "when sells has been changed within the current month" do
          before do
            Timecop.freeze(start_of_july + 10.days) do
              # NOTE: Sells is changed between when order1 and order2 are placed
              enterprise.update_attribute(:sells, 'own')
            end
          end

          travel_to(28.days)

          it "processes each sells period separately" do
            allow(updater).to receive(:split_for_trial).twice
            updater.perform

            expect(updater).to have_received(:split_for_trial)
            .with(enterprise.versions.first.reify, start_of_july, start_of_july + 10.days, nil, nil)

            expect(updater).to have_received(:split_for_trial)
            .with(enterprise, start_of_july + 10.days, start_of_july + 28.days, nil, nil)
          end
        end

        context "when owner has been changed within the current month" do
          let!(:new_owner) { create(:user) }

          before do
            Timecop.freeze(start_of_july + 10.days) do
              # NOTE: Sells is changed between when order1 and order2 are placed
              enterprise.update_attribute(:owner, new_owner)
            end
          end

          travel_to(28.days)

          it "processes each ownership period separately" do
            allow(updater).to receive(:split_for_trial).twice
            updater.perform

            expect(updater).to have_received(:split_for_trial)
            .with(enterprise.versions.first.reify, start_of_july, start_of_july + 10.days, nil, nil)

            expect(updater).to have_received(:split_for_trial)
            .with(enterprise, start_of_july + 10.days, start_of_july + 28.days, nil, nil)
          end
        end

        context "when some other attribute has been changed within the current month" do
          before do
            Timecop.freeze(start_of_july + 10.days) do
              # NOTE: Sells is changed between when order1 and order2 are placed
              enterprise.update_attribute(:name, 'Some New Name')
            end
          end

          travel_to(28.days)

          it "does not create a version, and so does not split the period" do
            expect(enterprise.versions).to eq []
            allow(updater).to receive(:split_for_trial).once
            updater.perform
            expect(updater).to have_received(:split_for_trial)
            .with(enterprise, start_of_july, start_of_july + 28.days, nil, nil)
          end
        end

        context "where sells or owner_id were altered during the previous month (ie. June)" do
          let!(:new_owner) { create(:user) }

          before do
            Timecop.freeze(start_of_july - 20.days) do
              # NOTE: Sells is changed between when order1 and order2 are placed
              enterprise.update_attribute(:sells, 'own')
            end
            Timecop.freeze(start_of_july - 10.days) do
              # NOTE: Sells is changed between when order1 and order2 are placed
              enterprise.update_attribute(:owner, new_owner)
            end
          end

          travel_to(28.days)

          it "ignores those verions" do
            allow(updater).to receive(:split_for_trial).once
            updater.perform
            expect(updater).to have_received(:split_for_trial)
            .with(enterprise, start_of_july, start_of_july + 28.days, nil, nil)
          end
        end
      end

      context "when an enterprise is created during the current month" do
        before do
          enterprise.update_attribute(:created_at, start_of_july + 10.days)
        end

        travel_to(28.days)

        it "begins at the date the enterprise was created" do
          allow(updater).to receive(:split_for_trial).once
          updater.perform
          expect(updater).to have_received(:split_for_trial)
          .with(enterprise, start_of_july + 10.days, start_of_july + 28.days, nil, nil)
        end
      end

      pending "when an enterprise is deleted during the current month" do
        before do
          enterprise.update_attribute(:deleted_at, start_of_july + 20.days)
        end

        travel_to(28.days)

        it "ends at the date the enterprise was deleted" do
          allow(updater).to receive(:split_for_trial)
          updater.perform
          expect(updater).to have_received(:split_for_trial)
          .with(enterprise, start_of_july, start_of_july + 20.days, nil, nil)
        end
      end
    end

    describe "split_for_trial" do
      let!(:enterprise) { double(:enterprise) }
      let(:begins_at) { start_of_july }
      let(:ends_at) { begins_at + 30.days }

      context "when trial_start is nil" do
        let(:trial_start) { nil }
        let(:trial_expiry) { begins_at + 3.days }

        before do
          allow(updater).to receive(:update_bill_item).once
          updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
        end

        it "calls update_bill_item once for the entire period" do
          expect(updater).to have_received(:update_bill_item)
          .with(enterprise, begins_at, ends_at, false)
        end
      end

      context "when trial_expiry is nil" do
        let(:trial_start) { begins_at + 3.days }
        let(:trial_expiry) { nil }

        before do
          allow(updater).to receive(:update_bill_item).once
          updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
        end

        it "calls update_bill_item once for the entire period" do
          expect(updater).to have_received(:update_bill_item)
          .with(enterprise, begins_at, ends_at, false)
        end
      end

      context "when the trial begins before begins_at" do
        let(:trial_start) { begins_at - 10.days }

        context "and the trial ends before begins_at" do
          let(:trial_expiry) { begins_at - 5.days }

          before do
            allow(updater).to receive(:update_bill_item).once
            updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
          end

          it "calls update_bill_item once for the entire period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, begins_at, ends_at, false)
          end
        end

        context "and the trial ends after begins_at" do
          let(:trial_expiry) { begins_at + 5.days }

          before do
            allow(updater).to receive(:update_bill_item).twice
            updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
          end

          it "calls update_bill_item once for the trial period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, begins_at, trial_expiry, true)
          end

          it "calls update_bill_item once for the non-trial period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, trial_expiry, ends_at, false)
          end
        end

        context "and the trial ends after ends_at" do
          let(:trial_expiry) { ends_at + 5.days }

          before do
            allow(updater).to receive(:update_bill_item).once
            updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
          end

          it "calls update_bill_item once for the entire (trial) period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, begins_at, ends_at, true)
          end
        end
      end

      context "when the trial begins after begins_at" do
        let(:trial_start) { begins_at + 5.days }

        context "and the trial begins after ends_at" do
          let(:trial_start) { ends_at + 5.days }
          let(:trial_expiry) { ends_at + 10.days }

          before do
            allow(updater).to receive(:update_bill_item).once
            updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
          end

          it "calls update_bill_item once for the entire period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, begins_at, ends_at, false)
          end
        end

        context "and the trial ends before ends_at" do
          let(:trial_expiry) { ends_at - 2.days }

          before do
            allow(updater).to receive(:update_bill_item).exactly(3).times
            updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
          end

          it "calls update_bill_item once for the non-trial period before the trial" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, begins_at, trial_start, false)
          end

          it "calls update_bill_item once for the trial period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, trial_start, trial_expiry, true)
          end

          it "calls update_bill_item once for the non-trial period after the trial" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, trial_expiry, ends_at, false)
          end
        end

        context "and the trial ends after ends_at" do
          let(:trial_expiry) { ends_at + 5.days }

          before do
            allow(updater).to receive(:update_bill_item).twice
            updater.split_for_trial(enterprise, begins_at, ends_at, trial_start, trial_expiry)
          end

          it "calls update_bill_item once for the non-trial period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, begins_at, trial_start, false)
          end

          it "calls update_bill_item once for the trial period" do
            expect(updater).to have_received(:update_bill_item)
            .with(enterprise, trial_start, ends_at, true)
          end
        end
      end
    end

    describe "update_bill_item" do
      let!(:enterprise) { create(:enterprise, sells: 'any') }

      let!(:existing) { create(:bill_item, enterprise: enterprise, begins_at: start_of_july) }

      context "when arguments match both 'begins_at' and 'enterprise_id' of an existing bill item" do
        it "updates the existing bill item" do
          expect{
            updater.update_bill_item(enterprise, start_of_july, start_of_july + 20.days, false)
          }.to_not change{ BillItem.count }
          existing.reload
          expect(existing.owner_id).to eq enterprise.owner_id
          expect(existing.ends_at).to eq start_of_july + 20.days
          expect(existing.sells).to eq enterprise.sells
          expect(existing.trial).to eq false
        end
      end

      context "when 'begins_at' does not match an existing bill item" do
        before do
          expect{
            updater.update_bill_item(enterprise, start_of_july + 20.days, start_of_july + 30.days, false)
          }.to change{ BillItem.count }.from(1).to(2)
        end

        it "creates a new existing bill item" do
          bill_item = BillItem.last
          expect(bill_item.owner_id).to eq enterprise.owner_id
          expect(bill_item.ends_at).to eq start_of_july + 30.days
          expect(bill_item.sells).to eq enterprise.sells
          expect(bill_item.trial).to eq false
        end
      end

      context "when 'enterprise_id' does not match an existing bill item" do
        let!(:new_enterprise) { create(:enterprise, sells: 'own') }

        before do
          expect{
            updater.update_bill_item(new_enterprise, start_of_july, start_of_july + 20.days, false)
          }.to change{ BillItem.count }.from(1).to(2)
        end

        it "creates a new existing bill item" do
          bill_item = BillItem.last
          expect(bill_item.owner_id).to eq new_enterprise.owner_id
          expect(bill_item.ends_at).to eq start_of_july + 20.days
          expect(bill_item.sells).to eq new_enterprise.sells
          expect(bill_item.trial).to eq false
        end
      end
    end
  end

  describe "validation tests" do
    # Chose july to test with because June has 30 days and so is easy to calculate end date for shop trial
    let!(:start_of_july) { Time.now.beginning_of_year + 6.months }

    let!(:enterprise) { create(:supplier_enterprise, sells: 'any') }

    let!(:order1) { create(:order, completed_at: start_of_july + 5.days, distributor: enterprise) }
    let!(:order2) { create(:order, completed_at: start_of_july + 15.days, distributor: enterprise) }
    let!(:order3) { create(:order, completed_at: start_of_july + 25.days, distributor: enterprise) }

    before do
      order1.line_items = [ create(:line_item, price: 12.56, order: order1) ]
      order2.line_items = [ create(:line_item, price: 87.44, order: order2) ]
      order3.line_items = [ create(:line_item, price: 50.00, order: order3) ]
      [order1, order2, order3].each(&:update!)
    end

    context "where the enterprise existed at the beginning of the current billing period", versioning: true do
      before do
        enterprise.update_attribute(:created_at, start_of_july - 2.months)
      end

      context "where the sells and owner_id properties of the enterprise have not been altered within the current billing period" do
        before do
          Timecop.travel(start_of_july + 28.days)
        end

        after do
          Timecop.return
        end

        context "where no trial information has been set" do
          before do
            UpdateBillItems.new.perform
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
            UpdateBillItems.new.perform
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
            UpdateBillItems.new.perform
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
          Timecop.freeze(start_of_july + 10.days) do
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
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits the billing period into a separate item for each sells value" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'own']
            expect(bill_items.map(&:trial)).to eq [false, false]
          end

          it "splits the turnover for the month to date" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.last.turnover).to eq order2.total + order3.total
          end
        end

        context "where a trial ended during the current billing period, after sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 10.days)
            UpdateBillItems.new.perform
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
            UpdateBillItems.new.perform
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
            UpdateBillItems.new.perform
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
            UpdateBillItems.new.perform
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

      context "where the owner_id property of the enterprise has been altered within the current billing period" do
        let!(:original_owner) { enterprise.owner }
        let!(:new_owner) { create(:user) }

        before do
          Timecop.freeze(start_of_july + 10.days) do
            # NOTE: Sells is changed between when order1 and order2 are placed
            enterprise.update_attribute(:owner, new_owner)
          end

          Timecop.travel(start_of_july + 28.days)
        end

        after do
          Timecop.return
        end

        context "where no trial information has been set" do
          before do
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits the billing period into a separate item for each owner" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:owner_id)).to eq [original_owner.id, new_owner.id]
            expect(bill_items.map(&:sells)).to eq ['any', 'any']
            expect(bill_items.map(&:trial)).to eq [false, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july, start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits the turnover for the month to date" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.last.turnover).to eq order2.total + order3.total
          end
        end

        context "where a trial ended during the current billing period, after owner was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 10.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct ownership periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:owner_id)).to eq [original_owner.id, new_owner.id, new_owner.id]
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'any']
            expect(bill_items.map(&:trial)).to eq [true, true, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july, start_of_july + 10.days, start_of_july + 20.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 10.days, start_of_july + 20.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where a trial ended during the current billing period, before owner was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 22.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:owner_id)).to eq [original_owner.id, original_owner.id, new_owner.id]
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'any']
            expect(bill_items.map(&:trial)).to eq [true, false, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july,          start_of_july + 8.days,  start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq   [start_of_july + 8.days, start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq 0
            expect(bill_items.last.turnover).to eq (order2.total + order3.total)
          end
        end

        context "where the trial began part-way through the current billing period, after owner was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 18.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct ownership periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:owner_id)).to eq [original_owner.id, new_owner.id, new_owner.id]
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'any']
            expect(bill_items.map(&:trial)).to eq [false, false, true]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july,           start_of_july + 10.days, start_of_july + 18.days]
            expect(bill_items.map(&:ends_at)).to eq   [start_of_july + 10.days, start_of_july + 18.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where the trial began part-way through the current billing period, before owner was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 8.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct ownership periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:owner_id)).to eq [original_owner.id, original_owner.id, new_owner.id]
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'any']
            expect(bill_items.map(&:trial)).to eq [false, true, true]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july,          start_of_july + 8.days,  start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq   [start_of_july + 8.days, start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order1.total
            expect(bill_items.second.turnover).to eq 0
            expect(bill_items.last.turnover).to eq (order2.total + order3.total)
          end
        end
      end
    end

    context "where the enterprise was created after the beginning of the current billing period", versioning: true do
      before do
        enterprise.update_attribute(:created_at, start_of_july + 7.days)
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
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "creates a single bill item" do
            expect(bill_items.count).to eq 1
            expect(bill_items.map(&:sells)).to eq ['any']
            expect(bill_items.map(&:trial)).to eq [false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 28.days]
          end

          it "ignores orders completed before the enterprise was created" do
            expect(bill_items.first.turnover).to eq (order2.total + order3.total)
          end
        end

        context "where a trial ended during the current billing period" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 10.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'any']
            expect(bill_items.map(&:trial)).to eq [true, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 20.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 20.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where the trial began part-way through the current billing period" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 10.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'any']
            expect(bill_items.map(&:trial)).to eq [false, true]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits the turnover for the month to date" do
            expect(bill_items.first.turnover).to eq 0
            expect(bill_items.last.turnover).to eq order2.total + order3.total
          end
        end
      end

      context "where the sells property of the enterprise has been altered within the current billing period" do
        before do
          Timecop.freeze(start_of_july + 10.days) do
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
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits the billing period into a separate item for each sells value" do
            expect(bill_items.count).to eq 2
            expect(bill_items.map(&:sells)).to eq ['any', 'own']
            expect(bill_items.map(&:trial)).to eq [false, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits the turnover for the month to date" do
            expect(bill_items.first.turnover).to eq 0
            expect(bill_items.last.turnover).to eq order2.total + order3.total
          end
        end

        context "where a trial ended during the current billing period, after sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 10.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'own', 'own']
            expect(bill_items.map(&:trial)).to eq [true, true, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 10.days, start_of_july + 20.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 10.days, start_of_july + 20.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq 0
            expect(bill_items.second.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where a trial ended during the current billing period, before sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july - 22.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'own']
            expect(bill_items.map(&:trial)).to eq [true, false, false]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 8.days, start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 8.days, start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq 0
            expect(bill_items.second.turnover).to eq 0
            expect(bill_items.last.turnover).to eq (order2.total + order3.total)
          end
        end

        context "where the trial began part-way through the current billing period, after sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 18.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'own', 'own']
            expect(bill_items.map(&:trial)).to eq [false, false, true]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 10.days, start_of_july + 18.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 10.days, start_of_july + 18.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq 0
            expect(bill_items.second.turnover).to eq order2.total
            expect(bill_items.last.turnover).to eq order3.total
          end
        end

        context "where the trial began part-way through the current billing period, before sells was changed" do
          before do
            enterprise.update_attribute(:shop_trial_start_date, start_of_july + 8.days)
            UpdateBillItems.new.perform
          end

          let(:bill_items) { BillItem.order(:id) }

          it "splits out the distinct sells periods and trial period into separate bill items" do
            expect(bill_items.count).to eq 3
            expect(bill_items.map(&:sells)).to eq ['any', 'any', 'own']
            expect(bill_items.map(&:trial)).to eq [false, true, true]
            expect(bill_items.map(&:begins_at)).to eq [start_of_july + 7.days, start_of_july + 8.days, start_of_july + 10.days]
            expect(bill_items.map(&:ends_at)).to eq [start_of_july + 8.days, start_of_july + 10.days, start_of_july + 28.days]
          end

          it "splits out the trial period into a separate bill item" do
            expect(bill_items.first.turnover).to eq 0
            expect(bill_items.second.turnover).to eq 0
            expect(bill_items.last.turnover).to eq (order2.total + order3.total)
          end
        end
      end
    end
  end
end
