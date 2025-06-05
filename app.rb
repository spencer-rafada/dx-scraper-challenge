require 'dotenv/load'
require_relative 'db/setup'
require_relative 'lib/github/importer'
require_relative 'lib/models/repository'
require_relative 'lib/models/pull_request'
require_relative 'lib/models/review'
require_relative 'lib/models/user'

def main(org: nil, repo_limit: 30, pr_limit: 30)
  importer = GitHub::Importer.new

  print "Enter GitHub organization name: (vercel) "
  org = gets.chomp.strip
  org = 'vercel' if org.empty?

  puts "Fetching repos for #{org}..."
  repos = importer.fetch_repos(org, limit: 30)  # Increased limit to get more repos

  puts "Found #{repos.count} repos for #{org}"

  repos.each do |repo_data|
    # Create or update repository
    repository = Repository.find_or_initialize_by(name: repo_data.full_name)
    repository.update(
      name: repo_data.full_name,
      url: repo_data.html_url,
      private: repo_data.private,
      archived: repo_data.archived
    )

    puts "\nProcessing repository: #{repo_data.full_name}"
    
    begin
      # Fetch pull requests for the repository
      puts "  Fetching pull requests..."
      pull_requests = importer.fetch_pull_requests(repo_data.full_name, limit: 30)  # Adjust limit as needed
      
      puts "  Found #{pull_requests.count} pull requests"
      
      pull_requests.each do |pr_data|
        # Get full PR details
        pr_details = importer.fetch_pull_request_details(repo_data.full_name, pr_data.number)
        
        # Create or update pull request
        pull_request = PullRequest.find_or_initialize_by(number: pr_details.number, repository_id: repository.id)
        author = User.find_or_create_by(username: pr_details.user.login) if pr_details.user
        pull_request.update(
          title: pr_details.title,
          url: pr_details.html_url,
          author: author,
          pr_updated_at: pr_details.updated_at,
          closed_at: pr_details.closed_at,
          merged_at: pr_details.merged_at,
          additions: pr_details.additions,
          deletions: pr_details.deletions,
          changed_files: pr_details.changed_files,
          commits: pr_details.commits,
          repository_id: repository.id
        )
        
        # Fetch and save reviews for the pull request
        puts "    Fetching reviews for PR ##{pr_details.number}..."
        reviews = importer.fetch_pull_request_reviews(repo_data.full_name, pr_details.number)
        
        reviews.each do |review_data|
          next unless review_data.user

          reviewer = User.find_or_create_by(username: review_data.user.login)
          review = Review.find_or_initialize_by(
            pull_request_id: pull_request.id,
            reviewer_id: reviewer.id
          )
          review.update(
            state: review_data.state,
            submitted_at: review_data.submitted_at
          )
        end
        
        puts "    Processed PR ##{pr_details.number}: #{pr_details.title} (#{reviews.count} reviews)"
      end
      
    rescue Octokit::TooManyRequests => e
      puts "  Rate limited while processing #{repo_data.full_name}. Sleeping for 1 hour..."
      sleep(3600)  # Sleep for 1 hour if rate limited
      retry
    rescue Octokit::NotFound => e
      puts "  Repository #{repo_data.full_name} not found or inaccessible"
    rescue StandardError => e
      puts "  Error processing #{repo_data.full_name}: #{e.message}
  #{e.backtrace.join("\n")}"
    end
  end

  puts "\nDone processing all repositories!"
end

if __FILE__ == $0
  main(org: ARGV[0], repo_limit: ARGV[1], pr_limit: ARGV[2])
end
