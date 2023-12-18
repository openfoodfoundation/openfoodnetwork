# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConnectedApp, type: :model do
  it { is_expected.to belong_to :enterprise }

  it "stores data as json hash" do
    # This functionality is just Rails and would usually not warrant a spec but
    # it's the first time we use the json datatype in this codebase and
    # therefore it's a nice example to see how it works.
    expect(subject.data).to eq nil

    subject.enterprise = create(:enterprise)
    subject.data = { link: "https://example.net" }
    subject.save!
    subject.reload

    expect(subject.data).to eq({ "link" => "https://example.net" })
  end
end
