require 'dotenv/load'
require_relative 'db/setup'
require_relative 'lib/github/importer'
require_relative 'lib/models/repository'
require_relative 'lib/models/pull_request'
require_relative 'lib/models/review'
require_relative 'lib/models/user'
require_relative 'lib/utils/logger'

def main(org: nil, repo_limit: 30, pr_limit: 30, max_retries: 3)
  importer = GitHub::Importer.new(max_retries: max_retries)

  unless org
    print "Enter GitHub organization name: (vercel) "
    org = gets.chomp.strip
    org = 'vercel' if org.empty?
  end

  begin
    repos = importer.fetch_repos(org, limit: repo_limit)
    puts "📦 Found #{repos.count} repos for #{org}"

    repos.each do |repo_data|
      begin
        repository = Repository.find_or_initialize_by(org: org, repo_name: repo_data.name)
        repository.assign_attributes(
          url: repo_data.html_url,
          private: repo_data.private,
          archived: repo_data.archived
        )
        repository.save if repository.changed?

        puts "\n📁 Processing repository: #{repo_data.full_name}"
        pull_requests = importer.fetch_pull_requests(repo_data.full_name, limit: pr_limit)

        user_cache = {}

        pull_requests.each do |pr_data|
          pr_details = importer.fetch_pull_request_details(repo_data.full_name, pr_data.number)
          next unless pr_details

          pull_request = PullRequest.find_or_initialize_by(number: pr_details.number, repository_id: repository.id)

          author_login = pr_details.user&.login
          author = user_cache[author_login] ||= User.find_or_create_by(username: author_login) if author_login

          pull_request.assign_attributes(
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
          pull_request.save if pull_request.changed?

          reviews = importer.fetch_pull_request_reviews(repo_data.full_name, pr_details.number)
          reviews.each do |review_data|
            next unless review_data&.user
            reviewer_login = review_data.user.login

            reviewer = user_cache[reviewer_login] ||= User.find_or_create_by(username: reviewer_login)

            review = Review.find_or_initialize_by(
              pull_request_id: pull_request.id,
              reviewer_id: reviewer.id
            )
            review.assign_attributes(
              state: review_data.state,
              submitted_at: review_data.submitted_at
            )
            review.save if review.changed?
          end

          puts "✅ Processed PR ##{pr_details.number}: #{pr_details.title} (#{reviews.count} reviews)"
        end
      rescue => e
        puts "⚠️  Warning: Error processing repository #{repo_data&.full_name || 'unknown'}: #{e.message}"
        AppLogger.error("Error processing repository", exception: e, source: 'app')
        next
      end
    end

    puts "\n🎉 Done processing all repositories!"
  rescue => e
    puts "❌ Fatal error: #{e.message}"
    AppLogger.error("Fatal error in main process", exception: e, source: 'app')
    exit 1
  end
end

if __FILE__ == $0
  org = nil
  repo_limit = 30
  pr_limit = 30
  max_retries = ENV.fetch('MAX_RETRIES', 3).to_i

  ARGV.each_slice(2) do |arg, value|
    case arg
    when '-o', '--org'
      org = value
    when '-rl', '--repo-limit'
      repo_limit = value.to_i
    when '-prl', '--pr-limit'
      pr_limit = value.to_i
    when '-mr', '--max-retries'
      max_retries = value.to_i
    end
  end

  main(org: org, repo_limit: repo_limit, pr_limit: pr_limit, max_retries: max_retries)
end
