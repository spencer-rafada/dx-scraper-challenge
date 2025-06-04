require_relative 'client'

module GitHub
  class Importer
    def initialize
      @client = Client.connection
    end

    def fetch_repos(org, limit: 5)
      @client.org_repos(org, per_page: limit)
    end

    def fetch_pull_requests(repo, limit: 5)
      @client.pull_requests(repo, per_page: limit)
    end

    def fetch_pull_request_details(repo, pull_request_number)
      @client.pull_request(repo, pull_request_number)
    end

    def fetch_pull_request_reviews(repo, pull_request_number)
      @client.pull_request_reviews(repo, pull_request_number)
    end
  end
end
