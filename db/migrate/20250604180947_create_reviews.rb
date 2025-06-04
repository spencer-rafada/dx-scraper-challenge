class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.references :pull_request, null: false, foreign_key: true

      t.string :state
      t.datetime :submitted_at
      t.string :reviewer

      t.timestamps
    end
  end
end
