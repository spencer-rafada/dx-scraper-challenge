class AddReviewerToReviews < ActiveRecord::Migration[7.0]
  def change
    add_reference :reviews, :reviewer, foreign_key: { to_table: :users }, index: true
  end
end
