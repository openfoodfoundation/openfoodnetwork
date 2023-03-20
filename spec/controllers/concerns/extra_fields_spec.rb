# frozen_string_literal: true

require 'spec_helper'

describe ExtraFields do
  let(:dummy_controller) { Api::V1::BaseController.new.extend ExtraFields }

  describe "#invalid_query_param" do
    it "renders error" do
      allow(dummy_controller).to receive(:render) {}
      dummy_controller.invalid_query_param("param", :unprocessable_entity, "error message")
      expect(dummy_controller).to have_received(:render).with(
        json:
          {
            errors:
            [{
              code: 422,
              detail: "error message",
              source: { parameter: "param" },
              status: :unprocessable_entity,
              title: "Invalid query parameter"
            }]
          },
        status: :unprocessable_entity
      )
    end
  end

  describe "#extra_fields" do
    context "when fields present and available" do
      it "returns extra fields" do
        allow(dummy_controller).to receive(:params).
          and_return({ extra_fields: { customer: "balance" } })
        expect(dummy_controller.extra_fields(:customer, [:balance])).to eq([:balance])
      end
    end

    context "when fields missing" do
      it "returns empty arr" do
        allow(dummy_controller).to receive(:params).and_return({})
        expect(dummy_controller.extra_fields(:customer, [:balance])).to eq([])
      end
    end

    context "when fields not in available fields" do
      it "calls invalid_query_param" do
        allow(dummy_controller).to receive(:invalid_query_param) {}
        allow(dummy_controller).to receive(:params).
          and_return({ extra_fields: { customer: "unknown" } })
        dummy_controller.extra_fields(:customer, [:balance])

        expect(dummy_controller).to have_received(:invalid_query_param).with(
          "extra_fields[customer]",
          :unprocessable_entity,
          "Unsupported fields: unknown"
        )
      end
    end
  end
end
