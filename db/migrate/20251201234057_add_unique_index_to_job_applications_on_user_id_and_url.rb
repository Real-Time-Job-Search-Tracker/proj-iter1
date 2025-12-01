class AddUniqueIndexToJobApplicationsOnUserIdAndUrl < ActiveRecord::Migration[8.1]
  def change
    add_index :job_applications, [:user_id, :url], unique: true
  end
end
