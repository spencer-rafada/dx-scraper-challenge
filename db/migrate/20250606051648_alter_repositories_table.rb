class AlterRepositoriesTable < ActiveRecord::Migration[7.0]
  def change
    add_column :repositories, :org, :string
    add_column :repositories, :repo_name, :string
    
    remove_column :repositories, :name
    
    add_index :repositories, :org
    add_index :repositories, :repo_name
  end
end
