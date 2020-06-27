# frozen_string_literal: true

require 'spec_helper'

describe HomeController, type: :request do
  context "#unauthorized" do
    it "renders the unauthorized template" do
      get "/unauthorized"

      expect(response.status).to eq 401
      expect(response).to render_template("shared/unauthorized", layout: 'darkswarm')
    end
  end
end
