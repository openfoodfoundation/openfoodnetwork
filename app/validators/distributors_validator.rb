# frozen_string_literal: true

# This is workaround only for https://github.com/openfoodfoundation/openfoodnetwork/issues/1560#issuecomment-300832051
class DistributorsValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:base, I18n.t(:spree_distributors_error)) unless record.distributors.any?
  end
end
