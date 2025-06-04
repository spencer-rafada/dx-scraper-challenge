require 'dotenv/load'
require_relative 'db/setup'
require_relative 'lib/github/importer'
require_relative 'lib/models/repository'

importer = GitHub::Importer.new

org = 'vercel'

puts "Fetching repos for #{org}..."
repos = importer.fetch_repos(org)

puts "Found #{repos.count} repos for #{org}"

repos.each do |repo|
  puts "#{repo.full_name} - #{repo.html_url}"

  repository = Repository.find_or_initialize_by(name: repo.full_name)
  repository.update(
    name: repo.full_name,
    url: repo.html_url,
    private: repo.private,
    archived: repo.archived
  )
end

puts "Fetching pull request for Next.js repo..."
pull_requests = importer.fetch_pull_requests('vercel/next.js')

puts "Found #{pull_requests.count} pull requests for Next.js"

pull_requests.each do |pull_request|
  puts "#{pull_request.number}: #{pull_request.title} - #{pull_request.html_url}"
end

pr_details = importer.fetch_pull_request_details('vercel/next.js', 80160)

puts "PR ##{pr_details.number}: #{pr_details.title}"
puts "Author: #{pr_details.user.login}"
puts "Updated: #{pr_details.updated_at}"
puts "Closed: #{pr_details.closed_at}"
puts "Merged: #{pr_details.merged_at}"
puts "Additions: #{pr_details.additions}"
puts "Deletions: #{pr_details.deletions}"
puts "Changed Files: #{pr_details.changed_files}"
# puts "Commits: #{pr_details.commits}" # Commits

puts "Fetching reviews for PR ##{pr_details.number}..."
reviews = importer.fetch_pull_request_reviews('vercel/next.js', pr_details.number)

puts "Found #{reviews.count} reviews for PR ##{pr_details.number}"
reviews.each do |review|
  puts "#{review.user.login} - #{review.state} at #{review.submitted_at}"
end
