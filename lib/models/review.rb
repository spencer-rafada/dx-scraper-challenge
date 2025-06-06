require 'active_record'

class Review < ActiveRecord::Base
  self.table_name = 'reviews'

  belongs_to :pull_request
  belongs_to :reviewer, class_name: 'User'
end