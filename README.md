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
- Uses ActiveRecord for database operations

## Prerequisites

- Ruby
- Bundler
- SQLite3
- GitHub Personal Access Token with appropriate permissions (if not provided, rate limiting will be applied)

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/spencer-rafada/dx-scraper-challenge
   cd dx-scraper-challenge
   ```

2. Install dependencies:

   ```bash
   bundle install
   ```

3. Set up your database:

   ```bash
   rake db:migrate
   ```

4. Configure environment variables:
   Create a `.env` file in the root directory and grab the example `.env.example` file and copy it to `.env`

## Database Schema

The application uses the following database tables:

- `repositories`: Stores repository information
- `pull_requests`: Stores pull request data
- `reviews`: Stores code review information
- `users`: Tracks GitHub users
- `logs`: Stores any logs (errors, warnings, and info) that occur during scraping

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

## Data Model

### Repository

- id: Integer
- name: String
- url: String
- private: Boolean
- archived: Boolean
- created_at: DateTime
- updated_at: DateTime

### Pull Request

- id: Integer
- number: Integer
- title: String
- url: String
- additions: Integer
- deletions: Integer
- changed_files: Integer
- commits: Integer
- created_at: DateTime
- pr_updated_at: DateTime
- closed_at: DateTime
- merged_at: DateTime
- repository_id: ForeignKey
- author_id: ForeignKey
- updated_at: DateTime

### Review

- id: Integer
- state: String
- submitted_at: DateTime
- pull_request_id: ForeignKey
- reviewer_id: ForeignKey
- created_at: DateTime
- updated_at: DateTime

### User

- id: Integer
- username: String
- avatar_url: String
- created_at: DateTime
- updated_at: DateTime
