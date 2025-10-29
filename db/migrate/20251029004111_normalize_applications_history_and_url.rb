class NormalizeApplicationsHistoryAndUrl < ActiveRecord::Migration[7.1]
  def change

    change_column_default :applications, :history, from: nil, to: []


    add_index :applications, :url, unique: true unless index_exists?(:applications, :url, unique: true)
  end
end
