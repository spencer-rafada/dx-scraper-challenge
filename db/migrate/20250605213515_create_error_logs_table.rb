class CreateErrorLogsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :logs do |t|
      t.string :level, null: false
      t.string :message, null: false
      t.string :error_class
      t.text :backtrace
      t.text :error_message
      t.string :source

      t.timestamps
    end
  end
end
