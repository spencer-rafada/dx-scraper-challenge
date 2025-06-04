require 'octokit'

# No authentication
client = Octokit::Client.new

org = 'rails'  # Replace with any public organization
repos = client.org_repos(org)

repos.each do |repo|
  puts "#{repo.full_name} - #{repo.html_url}"
end
