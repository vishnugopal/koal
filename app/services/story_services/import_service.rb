require_relative "../support/service"

#
# Bulk import stories by the same author
#
# Params:
# `author`: A string author name
# `stories`:
#   An array of stories, each story is a tuple with structure:
#  ```
#     {
#       name: "The name of the story",
#       description: "A short description of the story used in front matter",
#       intro: "The intro text of the story, presented before Chapter 1.",
#       outro: "The outro text, presented after the last chapter.",
#       copyright_notice: "The copyright notice presented in the footer.",
#       series_name: A string for the series name, optional.
#       series_book_title: "The title of the book in the series, for e.g. 'Book I'",
#       series_book_order: "An integer, the order of the book in the series, starts with 1.",
#       chapters: [
#         title: "Title of the chapter",
#         contents: "An HTML-formatted contents of the chapter. Use simple <p/> tags for paragraphs, and <b>, <i>, <em>, <strong>, etc. for emphasis.",
#       ],
#     }
#  ```
#
class StoryServices::ImportService < Koal::Service
  def call(author:, stories:)
    author_record = Author.find_or_create_by(name: author)

    stories.each do |story|
      story_record = author_record.stories.find_by_name(story[:name])
      attributes = {
        name: story[:name],
        description: story[:description],
        intro: story[:intro],
        outro: story[:outro],
        copyright_notice: story[:copyright_notice],
        series_name: story[:series_name],
        series_book_title: story[:series_book_title],
        series_book_order: story[:series_book_order],
      }
      if story_record
        story_record ||= author_record.stories.update(attributes)
      else
        story_record ||= author_record.stories.create(attributes)
      end

      story[:chapters].each_with_index do |chapter_data, index|
        chapter_title = chapter_data[:title]
        chapter_content = chapter_data[:content]

        chapter = story_record.chapters.find_or_create_by(title: chapter_title)
        chapter.contents = chapter_content
        chapter.order = index + 1
        chapter.save
      end
    end

    completed!
  rescue Exception => e
    failed!(exception: e)
  end
end
