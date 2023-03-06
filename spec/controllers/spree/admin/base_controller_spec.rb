# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::BaseController, type: :controller do
  controller(Spree::Admin::BaseController) do
    def index
      before_action :unauthorized
      render plain: ""
    end
  end

  it "redirects to Angular login" do
    spree_get :index
    expect(response).to redirect_to root_path(anchor: "/login", after_login: "/spree/admin/base")
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
          expect(controller).to receive(:render).with(
            { json: data, each_serializer: "SerializerClass" }
          )
          controller.send(:render_as_json, data, ams_prefix: prefix)
        end
      end

      context "when no ams prefix is passed" do
        let(:prefix) { "prefix" }

        it "does not pass a prefix to the serializer method and renders with each_serializer" do
          expect(controller).to receive(:serializer).with(prefix) { "SerializerClass" }
          expect(controller).to receive(:render).with(
            { json: data, each_serializer: "SerializerClass" }
          )
          controller.send(:render_as_json, data, ams_prefix: prefix)
        end
      end
    end
  end

  describe "determining the name of the serializer to be used" do
    before do
      class Api::Admin::AllowedPrefixBaseSerializer; end;

      class Api::Admin::BaseSerializer; end;
      allow(controller).to receive(:ams_prefix_whitelist) { [:allowed_prefix] }
    end

    context "when a prefix is passed in" do
      context "and the prefix appears in the whitelist" do
        it "returns the requested serializer" do
          expect(controller.send(:serializer,
                                 'allowed_prefix')).to eq Api::Admin::AllowedPrefixBaseSerializer
        end
      end

      context "and the prefix does not appear in the whitelist" do
        it "raises an error" do
          expect{ controller.send(:serializer, 'other_prefix') }.to raise_error RuntimeError
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
