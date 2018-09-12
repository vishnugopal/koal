# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

home_folder = `cd ~; pwd`.strip

stories = [
  "Santos_J_Romeo@Adventures_of_Me_and_Martha_Jane",
  "gwresearch@Magestic",
  "Blackie@The_Book",
]

stories.each do |story|
  seed_data_folder = File.join(home_folder, "Downloads", story)

  if Dir.exist? seed_data_folder
    import_service = StoryServices::ImportService.call(folder: seed_data_folder)
    unless import_service.success?
      STDERR.puts "Import failed, are you sure the format is correct?"
      STDERR.puts import_service.exception.inspect.to_s
    end
  else
    STDERR.puts "Seed data directory does not exist. Download appropriate stories, unzip & put it in ~/Downloads"
    exit 1
  end
end
