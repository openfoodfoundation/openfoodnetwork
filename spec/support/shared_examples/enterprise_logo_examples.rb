# frozen_string_literal: true

RSpec.shared_examples "enterprise logo rendering" do |mail_method, enterprise_method|
  let(:logo) { double(variable?: true) }

  before do
    enterprise = public_send(enterprise_method)

    allow(enterprise).to receive(:logo).and_return(logo)
    allow(enterprise).to receive(:logo_url).with(:medium).and_return("/logo.png")
  end

  it "renders the logo" do
    body = public_send(mail_method).body.encoded

    expect(body).to include("/logo.png")
  end
end
