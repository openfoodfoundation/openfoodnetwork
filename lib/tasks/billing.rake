namespace :openfoodnetwork do
  namespace :billing do
    desc 'Update enterprise user invoices'
    task update_user_invoices: :environment do
      Delayed::Job.enqueue(UpdateUserInvoices.new) if Spree::Config[:auto_update_invoices]
    end

    desc 'Finalize enterprise user invoices'
    task finalize_user_invoices: :environment do
      Delayed::Job.enqueue(FinalizeUserInvoices.new) if Spree::Config[:auto_finalize_invoices]
    end
  end
end
