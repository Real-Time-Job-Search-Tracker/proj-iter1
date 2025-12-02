class RemoveUniqueIndexOnJobApplicationsUrl < ActiveRecord::Migration[8.1]
  def change
    remove_index :job_applications, name: "index_job_applications_on_url"
  end
end
