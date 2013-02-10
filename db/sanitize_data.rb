
def update_address(address, user)
  unless address.nil?
    address.firstname = user[:first_name]
    address.lastname = user[:last_name]
    address.phone = user[:phone]
    address.save!
  end
end

def sanitize_data
  canned_users = [ { :first_name => "Bob", :last_name => "jones", :email => "bob@jones.com", :phone => "0123456789" },
   { :first_name => "cindy", :last_name => "rest", :email => "cindy@gmail.com", :phone => "0123456789" },
   { :first_name => "Pete", :last_name => "smith", :email => "pete@gmail.com", :phone => "0123456789" },
   { :first_name => "Tony", :last_name => "ballantyne", :email => "tony@gmail.com", :phone => "0123456789" },
   { :first_name => "Ben", :last_name => "raven", :email => "ben@gmail.com", :phone => "0123456789" },
   { :first_name => "Robyn", :last_name => "monster", :email => "robyn@gmail.com", :phone => "0123456789" },
   { :first_name => "Nako", :last_name => "tolkein", :email => "nako@gmail.com", :phone => "0123456789" },
   { :first_name => "Helen", :last_name => "mitcham", :email => "helen@gmail.com", :phone => "0123456789" },
   { :first_name => "Emma", :last_name => "low", :email => "emma@gmail.com", :phone => "0123456789" },
   { :first_name => "Mandy", :last_name => "Trust", :email => "Mandy@trust.com", :phone => "0123456789" } ]

   Spree::Order.all.each_with_index do |order, index|
    canned_user = canned_users[index%canned_users.size]
    puts "updating order #{order.id} with #{canned_user[:first_name]}"

    order.email = canned_user[:email]

    update_address(order.bill_address, canned_user)
    update_address(order.ship_address, canned_user)
    order.save!
  end

  Spree::User.all.each_with_index do |user, index|
    unless user.email == "admin@openfoodweb.org"
     canned_user = canned_users[index%canned_users.size]
     puts "updating user #{user.id} with #{canned_user[:first_name]}"

     user.email = "#{canned_user[:email]}#{index}"
     user.save!
   end
 end
end