require 'active_record'
require 'rake'
require 'fileutils'
require_relative 'db/setup'

namespace :db do
  task :environment do
    require_relative 'db/setup'
  end

  desc 'Run database migrations'
  task migrate: :environment do
    ActiveRecord::MigrationContext.new('db/migrate').migrate
  end

  desc 'Create a new migration'
  task :new_migration, [:name] => :environment do |_t, args|
    timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S')
    name = args[:name].downcase.gsub(' ', '_')
    file_path = "db/migrate/#{timestamp}_#{name}.rb"
    class_name = name.split('_').map(&:capitalize).join

    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, <<~RUBY)
      class #{class_name} < ActiveRecord::Migration[7.0]
        def change
        end
      end
    RUBY

    puts "Created migration: #{file_path}"
  end

  desc 'Drop the database'
  task :drop => :environment do
    config = ActiveRecord::Base.connection_db_config
    `psql -U #{config.configuration_hash[:username]} -c "DROP DATABASE IF EXISTS #{config.database};"`
  end

  desc 'Create the database'
  task :create => :environment do
    config = ActiveRecord::Base.connection_db_config
    `psql -U #{config.configuration_hash[:username]} -c "CREATE DATABASE #{config.database};"`
  end

  desc 'Reset the database'
  task reset: [:drop, :create, :migrate]
end