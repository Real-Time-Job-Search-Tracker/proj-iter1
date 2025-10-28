class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications do |t|
      t.string :url
      t.string :company
      t.string :title
      t.string :status
      t.json :history

      t.timestamps
    end
  end
end
