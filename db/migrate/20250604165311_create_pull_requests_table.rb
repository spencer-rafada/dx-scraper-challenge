class CreatePullRequestsTable < ActiveRecord::Migration[7.0]
  def change 
    create_table :pull_requests do |t|
      t.references :repository, null: false, foreign_key: true

      t.integer  :number
      t.string   :title
      t.string   :url
      t.string   :author
      t.datetime :pr_updated_at
      t.datetime :closed_at
      t.datetime :merged_at
      t.integer  :additions
      t.integer  :deletions
      t.integer  :changed_files
      t.integer  :commits

      t.timestamps
    end
  end
end
