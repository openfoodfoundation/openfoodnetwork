# Sets a maximum number of returned records when Kaminari pagination is used on a query but no
# per_page value has been passed to the #per method.
Kaminari.configure do |config|
  config.max_per_page = 100
end
