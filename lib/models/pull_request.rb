require 'active_record'

class PullRequest < ActiveRecord::Base
  self.table_name = 'pull_requests'

  belongs_to :repository
  belongs_to :author, class_name: 'User'
  has_many :reviews
end