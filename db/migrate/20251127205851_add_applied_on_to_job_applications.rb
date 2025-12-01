class AddAppliedOnToJobApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :job_applications, :applied_on, :date
  end
end
