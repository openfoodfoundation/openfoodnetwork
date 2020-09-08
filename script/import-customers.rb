# frozen_string_literal: true

# Read customer entries in CSV format from STDIN and create those records in
# the database. Example:
#
#   rails runner script/import-customers.rb 3359 < FND-customers-Emails.csv
#
# This script was written for a once-off import. If we want to perform this
# task more often, we can make it more flexible and eventually add a
# feature to the user interface.
require 'csv'

enterprise_id = ARGV.first

def check_enterprise_exists(id)
  enterprise = Enterprise.find(id)
  puts "Importing customers for #{enterprise.name}:"
end

def import_customer(row, enterprise_id)
  email = row["Email"].downcase
  tag = row["Tag"]

  print email
  customer = find_or_create_customer(email, enterprise_id)
  add_tag(customer, tag)
  puts ""
end

def find_or_create_customer(email, enterprise_id)
  Customer.find_or_create_by(
    email: email,
    enterprise_id: enterprise_id,
  ) { print " - newly imported" }
  print " - user exists" if Spree::User.where(email: email).exists?
end

def add_tag(customer, tag)
  return if tag.blank?

  customer.tag_list.add(tag)
  customer.save!
end

check_enterprise_exists(enterprise_id)

CSV($stdin, headers: true, row_sep: "\r\n") do |csv|
  csv.each do |row|
    import_customer(row, enterprise_id)
  end
end
