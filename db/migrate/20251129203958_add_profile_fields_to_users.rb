class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :daily_goal, :integer
    add_column :users, :student_track, :string
    add_column :users, :default_job_title, :string
    add_column :users, :custom_job_title, :string
  end
end
