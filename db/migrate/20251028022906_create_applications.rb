class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      t.string :url,     null: false
      t.string :company, null: false
      t.string :title,   null: false
      t.string :status,  null: false, default: "Applied"
      t.json   :history, null: false, default: []

      t.timestamps
    end
    add_index :applications, :url, unique: true
  end
end
