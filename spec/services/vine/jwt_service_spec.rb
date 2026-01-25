# frozen_string_literal: true

RSpec.describe Vine::JwtService do
  describe "#generate_token" do
    subject { described_class.new(secret: vine_secret) }
    let(:vine_secret) { "some_secret" }

    it "generate a jwt token" do
      expect(subject.generate_token).to be_a String
    end

    it "includes issuing body" do
      token = subject.generate_token

      payload = decode(token, vine_secret)

      expect(payload["iss"]).to eq("openfoodnetwork")
    end

    it "includes issuing time" do
      generate_time = Time.zone.now
      travel_to(generate_time) do
        token = subject.generate_token

        payload = decode(token, vine_secret)

        expect(payload["iat"].to_i).to eq(generate_time.to_i)
      end
    end

    it "includes expirations time" do
      generate_time = Time.zone.now
      travel_to(generate_time) do
        token = subject.generate_token

        payload = decode(token, vine_secret)

        expect(payload["exp"].to_i).to eq((generate_time + 1.minute).to_i)
      end
    end
  end

  def decode(token, secret)
    JWT.decode(
      token,
      secret,
      true, { algorithm: "HS256" }
    ).first
  end
end
