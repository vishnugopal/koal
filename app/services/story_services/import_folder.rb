require_relative "../support/service"

module StoryServices
  class ImportFolder < Koal::Service
    VALID_SOURCES = [
      {source_type: :storiesonline, source_format: :html},
    ]

    def call(folder:, source_type:, source_format:, remove_folder_after_import: false)
      source = {source_type: source_type, source_format: source_format}
      raise ArgumentError unless VALID_SOURCES.include? source

      cover_file = File.join(folder, "cover.html")
      index_file = File.join(folder, "index.html")

      cover_doc = File.open(cover_file) { |f| Nokogiri::HTML(f) }
      index_doc = File.open(index_file) { |f| Nokogiri::HTML(f) }

      intro_text = nil
      intro_text_header = cover_doc.css(".end-note + h4")[0]&.inner_html
      if intro_text_header
        intro_text = cover_doc.css("h4 + blockquote").inner_html.strip
        intro_text = "<h4>#{intro_text_header}</h4>#{intro_text}"
      end

      story_description = cover_doc.css(".end-note p")[0].inner_text.gsub(/^Description:/, "")

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
                                      description: story_description,
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

      FileUtils.remove_entry_secure(folder) if remove_folder_after_import

      completed!
    rescue Exception => e
      failed!(exception: e)
    end
  end
end
