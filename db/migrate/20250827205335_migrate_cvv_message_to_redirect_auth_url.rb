# frozen_string_literal: true

class MigrateCvvMessageToRedirectAuthUrl < ActiveRecord::Migration[7.1]
  class SpreePayment < ActiveRecord::Base; end

  def up
    records = SpreePayment.where.not(
      cvv_response_message: nil
    ).where.not(
      state: :completed
    )

    records.update_all(
      "redirect_auth_url = cvv_response_message, cvv_response_message = null"
    )
  end

  def down
    records = SpreePayment.where.not(
      redirect_auth_url: nil
    ).where.not(
      state: :completed
    )

    records.update_all("cvv_response_message = redirect_auth_url, redirect_auth_url = null")
  end
end
