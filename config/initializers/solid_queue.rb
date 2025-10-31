if Rails.env.production?
  Rails.application.config.solid_queue.connects_to = {
    database: { writing: :primary, reading: :primary }
  }
end