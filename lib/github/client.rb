require 'octokit'

module GitHub
  class Client
    def self.connection
      @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN']).tap do |client|
        client.auto_paginate = true
      end
    end
  end
end