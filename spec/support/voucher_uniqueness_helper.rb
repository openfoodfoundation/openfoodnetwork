# frozen_string_literal: true

shared_examples_for 'has a unique code per enterprise' do |voucher_type|
  describe "code" do
    let(:code) { "super_code" }
    let(:enterprise) { create(:enterprise) }

    it "is unique per enterprise" do
      voucher = create(voucher_type, code:, enterprise:)
      expect(voucher).to be_valid

      expect_voucher_with_same_enterprise_to_be_invalid(voucher_type)

      expect_voucher_with_other_enterprise_to_be_valid(voucher_type)
    end

    context "with deleted voucher" do
      it "is unique per enterprise" do
        create(voucher_type, code:, enterprise:).destroy!

        expect_voucher_with_same_enterprise_to_be_invalid(voucher_type)

        expect_voucher_with_other_enterprise_to_be_valid(voucher_type)
      end
    end
  end

  def expect_voucher_with_same_enterprise_to_be_invalid(voucher_type)
    new_voucher = build(voucher_type, code:, enterprise: )

    expect(new_voucher).not_to be_valid
    expect(new_voucher.errors.full_messages).to include("Code has already been taken")
  end

  def expect_voucher_with_other_enterprise_to_be_valid(voucher_type)
    other_voucher = build(voucher_type, code:, enterprise: create(:enterprise) )
    expect(other_voucher).to be_valid
  end
end
