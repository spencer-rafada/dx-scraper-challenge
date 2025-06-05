require 'active_record'
require 'fileutils'

FileUtils.mkdir_p('db')

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/development.sqlite3'
)

# Load all models
Dir[File.join(__dir__, '../lib/models', '*.rb')].each { |file| require file }