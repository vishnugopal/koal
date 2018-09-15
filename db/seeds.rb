# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

home_folder = `cd ~; pwd`.strip
stories_folder = File.join(home_folder, "Downloads", "Books for Koal")

Dir.glob(File.join(stories_folder, "*")).select { |f| File.directory? f }.each do |story_folder|
  if Dir.exist? story_folder
    STDOUT.puts "Parsing #{story_folder}..."
    story_parse_service = StoryServices::ParseService.call(folder: story_folder)
    unless story_parse_service.success?
      STDERR.puts "Story parse failed, are you sure the format is correct?"
      STDERR.puts story_parse_service.exception.inspect
      STDERR.puts story_parse_service.exception.backtrace
      exit 1
    end
    story_import_service = StoryServices::ImportService.call(author: story_parse_service.author,
                                                             stories: story_parse_service.stories)
    unless story_import_service.success?
      STDERR.puts "Story import failed, are you sure the format is correct?"
      STDERR.puts story_import_service.exception.inspect
      STDERR.puts story_import_service.exception.backtrace
      exit 1
    end
  else
    STDERR.puts "Seed data directory does not exist. Download appropriate stories, unzip & put it in ~/Downloads"
    exit 1
  end
end
