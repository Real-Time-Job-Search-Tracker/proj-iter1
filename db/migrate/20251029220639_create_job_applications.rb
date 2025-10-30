class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications do |t|
      t.string :url,     null: false
      t.string :company, null: false
      t.string :title,   null: false
      t.string :status,  null: false, default: "Applied"
      t.json   :history, null: false, default: []

      t.timestamps
    end

    add_index :job_applications, :url, unique: true
  end
end
