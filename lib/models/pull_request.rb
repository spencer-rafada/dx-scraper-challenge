require 'active_record'

class PullRequest < ActiveRecord::Base
  self.table_name = 'pull_requests'

  belongs_to :repository
  has_many :reviews
end