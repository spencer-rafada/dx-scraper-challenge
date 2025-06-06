class Log < ActiveRecord::Base
  validates :level, inclusion: { in: %w[info warn error] }
  validates :message, presence: true

  def self.record(level:, message:, error: nil, source: nil)
    create!(
      level: level.to_s,
      message: message,
      error_class: error&.class&.to_s,
      backtrace: error&.backtrace&.join("\n"),
      error_message: error&.message,
      source: source
    )
  end
end