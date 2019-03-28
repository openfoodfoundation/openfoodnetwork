class DeleteObsoletePendingJobs < ActiveRecord::Migration
  def up
    Delayed::Job.all.each do |job|
      job.delete if job.name == "FinalizeAccountInvoices" ||
                    job.name == "UpdateAccountInvoices" ||
                    job.name == "UpdateBillablePeriods"
    end
  end
end
