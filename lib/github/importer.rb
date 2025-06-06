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
        reset_time = @client.rate_limit.resets_in
        message = "Rate limited. Rate limit resets in #{reset_time} seconds."
        AppLogger.warn(message, exception: e, source: 'github_importer')
        
        if attempts.zero? && !continue_after_rate_limit?(message, reset_time)
          puts "\n🛑 Operation cancelled by user."
          exit(0)
        end
        
        puts "🟠 [WARN] #{message} Retrying in 10 seconds..."
        sleep([reset_time, 10].min)  # Sleep for the smaller of reset_time or 10 seconds
        attempts += 1
        retry if attempts < @max_retries
        fallback
      rescue Octokit::NotFound => e
        message = "Resource not found: #{e.message}"
        AppLogger.error(message, exception: e, source: 'github_importer')
        puts "🔴 [ERROR] #{message}"
        fallback
      rescue StandardError => e
        message = "Unexpected error: #{e.message}"
        AppLogger.error(message, exception: e, source: 'github_importer')
        puts "🔴 [ERROR] #{message}"
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

    private

    def continue_after_rate_limit?(message, wait_time)
      puts "\n🟠 [WARN] #{message}"
      
      return true unless $stdin.tty?
      
      begin
        Timeout.timeout(60) do
          loop do
            print "Do you want to wait and continue? (Y/n) "
            response = $stdin.gets&.chomp&.downcase
            
            case response
            when '', 'y', 'yes'
              return true
            when 'n', 'no', 'q', 'quit', 'exit'
              return false
            else
              puts "Please enter 'y' to continue or 'n' to exit"
            end
          end
        end
      rescue Timeout::Error
        puts "\nNo response received, continuing with operation..."
        return true
      end
    end
  end
end
