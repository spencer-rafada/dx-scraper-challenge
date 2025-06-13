require 'dotenv/load'
require 'concurrent'
require_relative 'db/setup'
require_relative 'lib/github/importer'
require_relative 'lib/models/repository'
require_relative 'lib/models/pull_request'
require_relative 'lib/models/review'
require_relative 'lib/models/user'
require_relative 'lib/utils/logger'

def main(org: nil, repo_limit: 30, pr_limit: 30, max_retries: 3, thread_count: 4)
  importer = GitHub::Importer.new(max_retries: max_retries)
  @shutdown = Concurrent::AtomicBoolean.new(false)
  @shutdown_mutex = Mutex.new

  Signal.trap('INT') { handle_shutdown(@shutdown, @shutdown_mutex) }
  Signal.trap('TERM') { handle_shutdown(@shutdown, @shutdown_mutex) }

  unless org
    print "Enter GitHub organization name: (vercel) "
    org = gets.chomp.strip
    org = 'vercel' if org.empty?
  end

  begin
    repos = importer.fetch_repos(org, limit: repo_limit)
    puts "📦 Found #{repos.count} repos for #{org}"

    pool = Concurrent::FixedThreadPool.new(thread_count)
    user_cache = Concurrent::Map.new

    repos.each do |repo_data|
      break if @shutdown.true?
      
      pool.post do
        begin
          thread_id = Thread.current.object_id.to_s(36)
          
          next if @shutdown.true?
          
          ActiveRecord::Base.connection_pool.with_connection do
            repository = Repository.find_or_initialize_by(org: org, repo_name: repo_data.name)
            repository.update(
              url: repo_data.html_url,
              private: repo_data.private,
              archived: repo_data.archived
            )

            puts "\n[#{thread_id}] 📁 Processing repository: #{repo_data.full_name}"
            
            pull_requests = importer.fetch_pull_requests(repo_data.full_name, limit: pr_limit)
            next if @shutdown.true? || pull_requests.nil?

            pull_requests.each do |pr_data|
              break if @shutdown.true?
              
              pr_details = importer.fetch_pull_request_details(repo_data.full_name, pr_data.number)
              next unless pr_details

              ActiveRecord::Base.transaction do
                pull_request = PullRequest.find_or_initialize_by(number: pr_details.number, repository_id: repository.id)
                login = pr_details.user&.login

                author = user_cache[login] ||= begin
                  User.find_or_create_by(username: login)
                rescue ActiveRecord::RecordNotUnique
                  retry
                end if login

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

                reviews = importer.fetch_pull_request_reviews(repo_data.full_name, pr_details.number)
                next if reviews.nil?

                reviews.each do |review_data|
                  next unless (review_user = review_data&.user)
                  reviewer = user_cache[review_user.login] ||= begin
                    User.find_or_create_by(username: review_user.login)
                  rescue ActiveRecord::RecordNotUnique
                    retry
                  end

                  review = Review.find_or_initialize_by(
                    pull_request_id: pull_request.id,
                    reviewer_id: reviewer.id
                  )
                  review.update(
                    state: review_data.state,
                    submitted_at: review_data.submitted_at
                  )
                end

                puts "[#{thread_id}] ✅ Processed PR ##{pr_details.number}: #{pr_details.title} (#{reviews.count} reviews)"
              end
            end
          end
        rescue => e
          thread_id = Thread.current.object_id.to_s(36)
          puts "[#{thread_id}] ⚠️  Warning: Error processing repo #{repo_data.full_name}: #{e.message}"
          AppLogger.error("Error processing repo #{repo_data.full_name}", exception: e, source: 'app')
        end
      end
    end

    pool.shutdown
    pool.wait_for_termination

    if @shutdown.true?
      puts "\n🛑 Shutdown requested. Exiting gracefully..."
    else
      puts "\n🎉 Done processing all repositories!"
    end
  rescue => e
    thread_id = Thread.current.object_id.to_s(36)
    puts "[#{thread_id}] ❌ Fatal error: #{e.message}"
    AppLogger.error("Fatal error in main process", exception: e, source: 'app')
    exit 1
  end
end

def handle_shutdown(shutdown, mutex)
  mutex.synchronize do
    unless shutdown.true?
      puts "\n🛑 Shutdown requested. Finishing current tasks..."
      shutdown.make_true
    end
  end
end

if __FILE__ == $0
  org = nil
  repo_limit = 30
  pr_limit = 30
  max_retries = ENV.fetch('MAX_RETRIES', 3).to_i
  thread_count = 4  # tune based on DB (keep low for SQLite)

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
    when '-tc', '--threads'
      thread_count = value.to_i
    end
  end

  main(org: org, repo_limit: repo_limit, pr_limit: pr_limit, max_retries: max_retries, thread_count: thread_count)
end
