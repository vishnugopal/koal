# frozen_string_literal: true

require "nokogiri"

# :nodoc:
class Story < ApplicationRecord
  belongs_to :author
  has_many :chapters

  def self.load_from_file(folder:, source_type:, source_format:)
    raise ArgumentError unless source_type == :storiesonline
    raise ArgumentError unless source_format == :html

    cover_file = File.join(folder, "cover.html")
    index_file = File.join(folder, "index.html")

    cover_doc = File.open(cover_file) { |f| Nokogiri::HTML(f) }
    index_doc = File.open(index_file) { |f| Nokogiri::HTML(f) }

    intro_text_header = cover_doc.css(".end-note + h4")[0].inner_html
    intro_text = cover_doc.css("h4 + blockquote").inner_html.strip
    intro_text = "<h4>#{intro_text_header}</h4>#{intro_text}"

    story_name = index_doc.css("h3")[0].inner_html
    author_text = index_doc.css("h3 + h4")[0].inner_html.gsub(/^by /, "")
    copyright_notice = index_doc.css("h4 + h4")[0].inner_html

    chapter_files = index_doc.css("small a").collect do |link|
      File.join(folder, link["href"])
    end
    chapter_contents = []
    chapter_files.each do |chapter_file|
      chapter_doc = File.open(chapter_file) { |f| Nokogiri::HTML(f) }
      chapter_title = chapter_doc.css(".date + h3.center")[0].inner_html
      chapter_content = chapter_doc.css(".story p, .story hr").collect do |content|
        content.to_xhtml.strip
      end.join("\n")
      chapter_contents << {title: chapter_title, content: chapter_content}
    end

    # Do database operations
    author = Author.find_or_create_by(name: author_text)
    story = author.stories.find_by_name(story_name)
    story ||= author.stories.create(name: story_name,
                                    intro: intro_text,
                                    copyright_notice: copyright_notice)

    chapter_contents.each_with_index do |chapter_data, index|
      chapter_title = chapter_data[:title]
      chapter_content = chapter_data[:content]

      chapter = story.chapters.find_or_create_by(title: chapter_title)
      chapter.contents = chapter_content
      chapter.order = index + 1
      chapter.save
    end
  end
end
