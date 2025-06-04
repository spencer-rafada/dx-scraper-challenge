require 'dotenv/load'
require_relative 'lib/github/importer'

importer = GitHub::Importer.new

org = 'vercel'

puts "Fetching repos for #{org}..."
repos = importer.fetch_repos(org)

puts "Found #{repos.count} repos for #{org}"

repos.each do |repo|
  puts "#{repo.full_name} - #{repo.html_url}"
end