# Read customer entries in CSV format from STDIN and create those records in
# the database.
#
# This script was written for a once-off import. If we want to perform this
# task more often, we can make it more flexible and eventually add a
# feature to the user interface.
require 'csv'

# Willunga Farmers Market
enterprise_id = 2545

def update_or_create_customer(row, enterprise_id)
  email = row["Email"].downcase
  tag = row["Tag"]
  print email
  customer = Customer.find_or_create_by(
    email: email,
    enterprise_id: enterprise_id,
  ) { print " - newly imported" }
  if tag.present?
    customer.tag_list.add(tag)
    customer.save!
  end
  print " - user exists" if Spree::User.where(email: email).exists?
  puts ""
end

CSV($stdin, headers: true, row_sep: "\r\n") do |csv|
  csv.each do |row|
    update_or_create_customer(row, enterprise_id)
  end
end
