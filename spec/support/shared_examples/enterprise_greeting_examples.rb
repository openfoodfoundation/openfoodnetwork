# frozen_string_literal: true

RSpec.shared_examples "for an enterprise with contact name present" do |mail|
  it "uses the enterprise greeting with name" do
    enterprise.update!(contact_name: "Fred Farmer")

    expect(public_send(mail).body.encoded).to include("Dear Fred Farmer,")
  end
end

RSpec.shared_examples "for an enterprise with no contact name present" do |mail|
  it "uses the general greeting without name" do
    enterprise.update!(contact_name: nil)

    expect(public_send(mail).body.encoded).to include("Hello!")
  end
end
