require_relative "../support/service"

class StoryServices::ParseSOLService < Koal::Service
  attr_reader :author, :series, :stories

  def call(folder:)
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

    @author = author_text
    @series = nil
    @stories = [{
      name: story_name,
      description: story_description,
      intro: intro_text,
      outro: nil,
      copyright_notice: copyright_notice,
      series_book_title: nil,
      series_book_order: nil,
      chapters: chapter_contents,
    }]

    completed!
  rescue Exception => e
    failed!(exception: e)
  end
end
