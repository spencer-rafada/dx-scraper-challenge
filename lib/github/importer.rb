require_relative 'client'
require_relative '../utils/logger'

module GitHub
  class Importer
    def initialize(max_retries: 3)
      @client = Client.connection
      @max_retries = max_retries
    end

    def fetch_with_retries(fallback: nil)
      attempts = 0
      begin
        yield
      rescue Octokit::TooManyRequests => e
        reset_time = @client.rate_limit.resets_at
        wait_time = [(reset_time - Time.now).to_i, 60].max
        message = "Rate limited. Waiting for #{wait_time} seconds..."
        puts "🟠 [WARN] #{message}"
        AppLogger.warn(message, exception: e, source: 'github_importer')
        sleep(wait_time)
        attempts += 1
        retry if attempts < @max_retries
        fallback
      rescue Octokit::NotFound => e
        message = "Resource not found: #{e.message}"
        puts "🔴 [ERROR] #{message}"
        AppLogger.error(message, exception: e, source: 'github_importer')
        fallback
      rescue StandardError => e
        message = "Unexpected error: #{e.message}"
        puts "🔴 [ERROR] #{message}"
        AppLogger.error(message, exception: e, source: 'github_importer')
        fallback
      end
    end

    def fetch_repos(org, type: 'public', limit: 5)
      puts "🗂️  Fetching repositories for organization: #{org}"
      fetch_with_retries(fallback: []) { @client.org_repos(org, type: type, per_page: limit) }
    end

    def fetch_pull_requests(repo, limit: 5)
      puts "🛠️  Fetching pull requests for repo: #{repo}"
      fetch_with_retries(fallback: []) { @client.pull_requests(repo, per_page: limit) }
    end

    def fetch_pull_request_details(repo, pull_request_number)
      puts "🛠️  Fetching details for PR ##{pull_request_number} in #{repo}"
      fetch_with_retries(fallback: nil) { @client.pull_request(repo, pull_request_number) }
    end

    def fetch_pull_request_reviews(repo, pull_request_number)
      puts "🔍  Fetching reviews for PR ##{pull_request_number} in #{repo}"
      fetch_with_retries(fallback: []) { @client.pull_request_reviews(repo, pull_request_number) }
    end

  end
end
