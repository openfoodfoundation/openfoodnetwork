require 'spec_helper'

describe Spree::Admin::BaseController, type: :controller do
  controller(Spree::Admin::BaseController) do
    def index
      before_filter :unauthorized
      render text: ""
    end
  end

  it "redirects to Angular login" do
    spree_get :index
    response.should redirect_to root_path(anchor: "login?after_login=/spree/admin/base")
  end

  describe "displaying error messages for active distributors not ready for checkout" do
    it "generates an error message when there is one distributor" do
      distributor = double(:distributor, name: 'My Hub')
      controller.
        send(:active_distributors_not_ready_for_checkout_message, [distributor]).
        should ==
        "The hub My Hub is listed in an active order cycle, " +
        "but does not have valid shipping and payment methods. " +
        "Until you set these up, customers will not be able to shop at this hub."
    end

    it "generates an error message when there are several distributors" do
      d1 = double(:distributor, name: 'Hub One')
      d2 = double(:distributor, name: 'Hub Two')
      controller.
        send(:active_distributors_not_ready_for_checkout_message, [d1, d2]).
        should ==
        "The hubs Hub One, Hub Two are listed in an active order cycle, " +
        "but do not have valid shipping and payment methods. " +
        "Until you set these up, customers will not be able to shop at these hubs."
    end
  end

  describe "rendering as json ActiveModelSerializer" do
    context "when data is an object" do
      let(:data) { { attr: 'value' } }

      context "when an ams prefix is passed" do
        let(:prefix) { "prefix" }

        it "passes a prefix to the serializer method and renders with serializer" do
          expect(controller).to receive(:serializer).with(prefix) { "SerializerClass" }
          expect(controller).to receive(:render).with({ json: data, serializer: "SerializerClass" })
          controller.send(:render_as_json, data, ams_prefix: prefix)
        end
      end

      context "when no ams prefix is passed" do
        let(:prefix) { "prefix" }

        it "does not pass a prefix to the serializer method and renders with serializer" do
          expect(controller).to receive(:serializer).with(prefix) { "SerializerClass" }
          expect(controller).to receive(:render).with({ json: data, serializer: "SerializerClass" })
          controller.send(:render_as_json, data, ams_prefix: prefix)
        end
      end
    end

    context "when data is an array" do
      let(:data) { [{ attr: 'value' }] }

      context "when an ams prefix is passed" do
        let(:prefix) { "prefix" }

        it "passes a prefix to the serializer method and renders with each_serializer" do
          expect(controller).to receive(:serializer).with(prefix) { "SerializerClass" }
          expect(controller).to receive(:render).with({ json: data, each_serializer: "SerializerClass" })
          controller.send(:render_as_json, data, ams_prefix: prefix)
        end
      end

      context "when no ams prefix is passed" do
        let(:prefix) { "prefix" }

        it "does not pass a prefix to the serializer method and renders with each_serializer" do
          expect(controller).to receive(:serializer).with(prefix) { "SerializerClass" }
          expect(controller).to receive(:render).with({ json: data, each_serializer: "SerializerClass" })
          controller.send(:render_as_json, data, ams_prefix: prefix)
        end
      end
    end
  end

  describe "determining the name of the serializer to be used" do
    before do
      class Api::Admin::AllowedPrefixBaseSerializer;end;
      class Api::Admin::BaseSerializer;end;
      allow(controller).to receive(:ams_prefix_whitelist) { [:allowed_prefix] }
    end

    context "when a prefix is passed in" do
      context "and the prefix appears in the whitelist" do
        it "returns the requested serializer" do
          expect(controller.send(:serializer, 'allowed_prefix')).to eq Api::Admin::AllowedPrefixBaseSerializer
        end
      end

      context "and the prefix does not appear in the whitelist" do
        it "raises an error" do
          expect{controller.send(:serializer, 'other_prefix')}.to raise_error RuntimeError
        end
      end
    end

    context "when no prefix is passed in" do
      it "returns the default serializer" do
        expect(controller.send(:serializer, nil)).to eq Api::Admin::BaseSerializer
      end
    end
  end
end
