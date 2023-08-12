# frozen_string_literal: true

require 'spec_helper'

describe Invoice::DataPresenter do
  context "#display_date" do
    let(:invoice) { double(:invoice, date: '2023-08-01') }

    let(:presenter) { Invoice::DataPresenter.new(invoice) }
    it "prints in a format" do
      expect(presenter.display_date).to eq "August 01, 2023"
    end
  end
end
