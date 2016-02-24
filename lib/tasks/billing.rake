namespace :openfoodnetwork do
  namespace :billing do
    desc 'Update enterprise user invoices'
    task update_account_invoices: :environment do
      Delayed::Job.enqueue(UpdateAccountInvoices.new) if Spree::Config[:auto_update_invoices]
    end

    desc 'Finalize enterprise user invoices'
    task finalize_account_invoices: :environment do
      Delayed::Job.enqueue(FinalizeAccountInvoices.new) if Spree::Config[:auto_finalize_invoices]
    end
  end
end
