class DeleteObsoletePendingJobs < ActiveRecord::Migration[4.2]
  def up
    Delayed::Job.all.each do |job|
      job.delete if job.name == "FinalizeAccountInvoices" ||
                    job.name == "UpdateAccountInvoices" ||
                    job.name == "UpdateBillablePeriods"
    end
  end
end
