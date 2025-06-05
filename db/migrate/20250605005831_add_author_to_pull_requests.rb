class AddAuthorToPullRequests < ActiveRecord::Migration[7.0]
  def change
    add_reference :pull_requests, :author, foreign_key: { to_table: :users }, index: true
  end
end
