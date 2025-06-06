# DX GitHub Scraper Challenge

A Ruby application that scrapes GitHub data from the Vercel organization, including repositories, pull requests, reviews, and user information.

**Submitted by: [spencer-rafada](https://github.com/spencer-rafada)**

## Features

- Fetches all public repositories from the Vercel organization (or any other organization you specify)
- Retrieves pull requests for each repository
- Collects reviews for each pull request
- Tracks GitHub users who opened PRs or submitted reviews
- Handles GitHub API rate limiting
- Logs errors for debugging and monitoring
- Uses PostgreSQL with ActiveRecord for concurrent database operations

## Prerequisites

- Ruby
- PostgreSQL
- Bundler
- GitHub Personal Access Token with appropriate permissions (if not provided, rate limiting will be applied)

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/spencer-rafada/dx-scraper-challenge
   cd dx-scraper-challenge
   ```

2. Install system dependencies (macOS):

   ```bash
   brew install postgresql
   ```

3. Install Ruby dependencies:

   ```bash
   bundle install
   ```

4. Set up PostgreSQL:

   - Make sure PostgreSQL is running
   - Create a database user (if needed):
     ```bash
     createuser --superuser $USER
     ```
   - Create the development database:
     ```bash
     createdb dx_scraper_development
     ```

5. Configure environment variables:

   ```bash
   cp .env.example .env
   ```

   Then edit `.env` and set your GitHub token and database credentials.

6. Set up the database:
   ```bash
   bundle exec rake db:migrate
   ```

## Database Management

- Create the database: `rake db:create`
- Run migrations: `rake db:migrate`
- Reset the database: `rake db:reset` (drops, recreates, and migrates)

## Database Schema and Model

The application uses the following database tables:

- `repositories`: Stores repository information
- `pull_requests`: Stores pull request data
- `reviews`: Stores code review information
- `users`: Tracks GitHub users
- `logs`: Stores any logs (errors, warnings, and info) that occur during scraping

![Database Schema](/public/db_schema.png)

## Usage

Run the main importer:

```bash
ruby app.rb
```

This will:

1. Fetch all public repositories from the Vercel organization (or any other organization you specify)
2. For each repository, fetch all pull requests
3. For each pull request, fetch all reviews
4. Store all users who opened PRs or submitted reviews

## Configuration

You can configure the following CLI arguments or flags:

- `--org` or `-o`: GitHub organization name (default: "vercel")
- `--repo-limit` or `-rl`: Number of repositories to fetch (default: 30)
- `--pr-limit` or `-prl`: Number of pull requests to fetch per repository (default: 30)
- `--max-retries` or `-mr`: Maximum number of retries for failed requests (default: 3)

## Error Handling

The application includes comprehensive error handling and logging:

- Rate limiting is automatically handled with max retries and prompt user to proceed or exit
- All logs (errors, warnings, and info) are logged to the `logs` table
- The scraper can be safely interrupted and resumed

## Concurrency

This application is designed to work with PostgreSQL's concurrency features:

- Uses thread pooling for parallel processing of repositories
- Implements proper connection pooling with ActiveRecord
- Uses database transactions to ensure data consistency
- Handles concurrent database operations safely

## GitHub Actions

This project includes a GitHub Actions workflow that runs the scraper with PostgreSQL. The workflow:

1. Sets up a PostgreSQL service
2. Installs required system dependencies
3. Sets up Ruby and installs gems
4. Creates and migrates the database
5. Runs the scraper with configurable parameters

### Manual Trigger

You can manually trigger the workflow from the Actions tab with these parameters:

- `org`: GitHub organization name (default: 'vercel')
- `repo_limit`: Number of repositories to fetch (default: 30)
- `pr_limit`: Number of pull requests to fetch per repository (default: 30)
- `max_retries`: Maximum number of retries for failed requests (default: 3)
- `thread_count`: Number of threads to use for processing (default: 4)
