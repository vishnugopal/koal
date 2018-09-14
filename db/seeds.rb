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
  "Tarrin Kael Firestaff Series by Fel",
  "Tarrin Kael Pyrosian Chronicles by Fel",
]

stories.each do |story|
  seed_data_folder = File.join(home_folder, "Downloads", story)

  if Dir.exist? seed_data_folder
    story_parse_service = StoryServices::ParseService.call(folder: seed_data_folder)
    unless story_parse_service.success?
      STDERR.puts "Story parse failed, are you sure the format is correct?"
      exit 1
    end
    story_import_service = StoryServices::ImportService.call(author: story_parse_service.author,
                                                             series: story_parse_service.series,
                                                             stories: story_parse_service.stories)
    unless story_import_service.success?
      STDERR.puts "Story import failed, are you sure the format is correct?"
      STDERR.puts story_import_service.exception.inspect.to_s
      exit 1
    end
  else
    STDERR.puts "Seed data directory does not exist. Download appropriate stories, unzip & put it in ~/Downloads"
    exit 1
  end
end
