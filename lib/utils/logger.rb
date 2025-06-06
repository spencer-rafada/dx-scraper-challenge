require_relative '../models/log'

class AppLogger
  def self.log(level:, message:, exception: nil, source: 'app')
    Log.record(
      level: level.to_s,
      message: message,
      error: exception,
      source: source
    )
  rescue => e
    puts "❌ Failed to write to logs: #{e.message}"
  end

  def self.info(message, source: 'app')
    log(level: :info, message: message, source: source)
  end

  def self.warn(message, exception: nil, source: 'app')
    log(level: :warn, message: message, exception: exception, source: source)
  end

  def self.error(message, exception: nil, source: 'app')
    log(level: :error, message: message, exception: exception, source: source)
  end
end
