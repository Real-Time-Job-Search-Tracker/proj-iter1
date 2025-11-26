class AddUserIdToJobApplications < ActiveRecord::Migration[8.1]
  def change
    add_reference :job_applications, :user, null: true, foreign_key: true
  end
end
