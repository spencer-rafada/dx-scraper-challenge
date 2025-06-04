require_relative 'client'

module GitHub
  class Importer
    def initialize
      @client = Client.connection
    end

    def fetch_repos(org, limit: 5)
      @client.org_repos(org, per_page: limit)
    end
  end
end
