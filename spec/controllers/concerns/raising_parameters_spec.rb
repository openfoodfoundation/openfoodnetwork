# frozen_string_literal: true

require 'spec_helper'

describe RaisingParameters do
  describe "Parameters" do
    let(:params) do
      RaisingParameters::Parameters.new(
        controller: "example",
        action: "update",
        data: {
          id: "unique",
          admin: true,
        }
      )
    end

    it "raises an error when a parameter is not permitted" do
      expect {
        params.require(:data).permit(:id)
      }.to raise_error(
        ActionController::UnpermittedParameters
      )
    end

    it "raises no error when all parameters are permitted" do
      expect {
        params.require(:data).permit(:id, :admin)
      }.to_not raise_error
    end

    it "doesn't change standard parameter objects" do
      original_params = ActionController::Parameters.new(one: 1, two: 2)

      expect {
        original_params.permit(:one)
      }.to_not raise_error
    end
  end
end
