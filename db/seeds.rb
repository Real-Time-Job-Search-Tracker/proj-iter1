# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
require 'json'

path = Rails.root.join("db/fake_jobs.json")
puts "📂 Loading fake data from #{path}"  

data = JSON.parse(File.read(path))

data.each_with_index do |job, i|
  app = JobApplication.new(
    url: job["url"],
    company: job["company"],
    title: job["title"],
    status: job["status"],
    history: job["history"]
  )
  if app.save
    puts "Seeded #{i+1}: #{app.company} (#{app.status})"
  else
    puts "Failed #{i+1}: #{app.errors.full_messages.join(", ")}"
  end
end

puts "Seeding complete. Total: #{JobApplication.count}"
