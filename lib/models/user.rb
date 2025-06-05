require 'active_record'

class User < ActiveRecord::Base
  self.table_name = 'users'

  has_many :authored_pull_requests, class_name: 'PullRequest', foreign_key: 'author_id'
  has_many :authored_reviews, class_name: 'Review', foreign_key: 'reviewer_id'
end
