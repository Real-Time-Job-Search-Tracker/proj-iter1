# db/seeds.rb
require 'json'

path = Rails.root.join("db", "fake_jobs.json")
puts "📂 Loading fake data from #{path}"

data = JSON.parse(File.read(path))

data.each_with_index do |job, i|
  app = JobApplication.find_or_initialize_by(url: job["url"])

  app.assign_attributes(
    company: job["company"],
    title: job["title"],
    status: job["status"],
    history: job["history"]
  )

  if app.save
    action = app.persisted? ? "Updated" : "Created"
    puts "✅ #{action} #{i+1}: #{app.company} (#{app.status})"
  else
    puts "❌ Failed #{i+1}: #{app.errors.full_messages.join(", ")}"
  end
end

puts "🌱 Seeding complete. Total in DB: #{JobApplication.count}"