require 'active_record'
require 'dotenv/load'
require 'pg'

ActiveRecord::Base.establish_connection(
  adapter:  'postgresql',
  encoding: 'unicode',
  database: ENV.fetch('PG_DATABASE'),
  username: ENV.fetch('PG_USERNAME'),
  password: ENV['PG_PASSWORD'],  
  host:     ENV.fetch('PG_HOST', 'localhost'),
  port:     ENV.fetch('PG_PORT', '5432')
)


# Load models
Dir[File.join(__dir__, '../lib/models', '*.rb')].each { |f| require f }
