class CreateUsersTable < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :username, null: false 
      t.string :avatar_url
      t.timestamps
    end

    add_index :users, :username, unique: true
  end
end
