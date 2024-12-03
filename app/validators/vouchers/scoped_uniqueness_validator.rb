# frozen_string_literal: false

# paranoia doesn't support unique validation including deleted records:
#  https://github.com/rubysherpas/paranoia/pull/333
# We use a custom validator to fix the issue, so we don't need to fork/patch the gem
module Vouchers
  class ScopedUniquenessValidator < ActiveModel::Validator
    def validate(record)
      @record = record

      return unless unique_voucher_code_per_enterprise?

      record.errors.add :code, :taken, value: @record.code
    end

    private

    def unique_voucher_code_per_enterprise?
      query = Voucher.with_deleted.where(code: @record.code, enterprise_id: @record.enterprise_id)
      query = query.where.not(id: @record.id) unless @record.id.nil?

      query.present?
    end
  end
end
