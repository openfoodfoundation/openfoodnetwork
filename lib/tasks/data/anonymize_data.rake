# frozen_string_literal: true

require 'highline'

namespace :ofn do
  namespace :data do
    desc 'Anonymize data'
    task anonymize: :environment do
      guard_and_warn

      anonymize_users_data

      Spree::Address.update_all("
        firstname = concat('Ms. Number', id), lastname = 'Jones',  phone = '01234567890',
        alternative_phone = '01234567890', address1 = 'Dummy address',
        address2 = 'Dummy address continuation',
        company = null, latitude = null, longitude = null")

      anonymize_payments_data
      anonymize_payments_accounts

      Spree::TokenizedPermission.update_all("token = null")

      # Delete all preferences that may contain sensitive information
      Spree::Preference
        .where("key like '%gateway%' OR key like '%billing_integration%' OR key like '%s3%'")
        .delete_all
    end

    def guard_and_warn
      if Rails.env.production?
        Rails.logger.info("This task cannot be executed in production")
        exit
      end

      message = "\n <%= color('This will permanently change DB contents', :yellow) %>,
                are you sure you want to proceed? (y/N)"
      exit unless HighLine.new.agree(message) { |q| q.default = "n" }
    end

    private

    def anonymize_users_data
      Spree::User.update_all("email = concat(id, '_ofn_user@example.com'),
                              login = concat(id, '_ofn_user@example.com'),
                              unconfirmed_email = concat(id, '_ofn_user@example.com')")
      Customer.where(user_id: nil)
        .update_all("email = concat(id, '_ofn_customer@example.com'),
                     name = concat('Customer Number ', id, ' (without connected User)'),
                     first_name = concat('Customer Number ', id),
                     last_name = '(without connected User)'")
      Customer.where.not(user_id: nil)
        .update_all("email = concat(user_id, '_ofn_user@example.com'),
                     name = concat('Customer Number ', id, ' - User ', user_id),
                     first_name = concat('Customer Number ', id),
                     last_name = concat('User ', user_id)")

      Spree::Order.update_all("email = concat(id, '_ofn_order@example.com')")
    end

    def anonymize_payments_data
      Spree::PaymentMethod.update_all("name = concat('Dummy Payment Method', id),
                                       description = name,
                                       environment = '#{Rails.env}'")
      Spree::Payment.update_all("response_code = null, avs_response = null,
                                 cvv_response_code = null, identifier = null,
                                 cvv_response_message = null")
      Spree::CreditCard.update_all("
        month = 12, year = 2020, start_month = 12, start_year = 2000,
        cc_type = 'VISA', first_name = 'Dummy', last_name = 'Dummy', last_digits = '2543'")
    end

    def anonymize_payments_accounts
      Spree::PaypalExpressCheckout.update_all("token = null")
      StripeAccount.delete_all
      ActiveRecord::Base.connection.execute("delete from spree_paypal_accounts")
    end
  end
end
