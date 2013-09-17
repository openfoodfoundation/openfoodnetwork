require 'open_food_web/notify_invalid_address_save'

module OpenFoodWeb
  describe NotifyInvalidAddressSave do
    describe "notifying bugsnag when a Spree::Address is saved with missing data" do
      it "notifies on create" do
        Bugsnag.should_receive(:notify)
        a = Spree::Address.new zipcode: nil
        a.save validate: false
      end

      it "notifies on update" do
        Bugsnag.should_receive(:notify)
        a = create(:address)
        a.zipcode = nil
        a.save validate: false
      end
    end
  end
end
