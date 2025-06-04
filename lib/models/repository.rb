require 'active_record'

class Repository < ActiveRecord::Base
  self.table_name = 'repositories'

  has_many :pull_requests
end