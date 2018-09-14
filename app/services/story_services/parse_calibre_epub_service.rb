# encoding: UTF-8

require_relative "../support/service"

class StoryServices::ParseCalibreEPUBService < Koal::Service
  attr_reader :author, :series, :stories

  def call(folder:)
    content_xml_file = File.join(folder, "content.opf")
    content_xml_doc = File.open(content_xml_file) { |f| Nokogiri::XML(f) }
    content_xml_doc.remove_namespaces!

    author_text_node = content_xml_doc.xpath("//creator")
    author_text = author_text_node.inner_text

    series_name_node = content_xml_doc.xpath("//meta[@name='calibre:series']")
    series_name = series_name_node[0]&.attribute("content")&.inner_text

    story_name_node = content_xml_doc.xpath("//title")
    story_name = story_name_node.inner_text
    if story_name[-1] == "©"
      story_name.chop!
    end

    series_book_title, story_name = story_name.split(" - ")
    series_book_order = series_book_title.match(/Book (\d{1,2})/)&.public_send(:[], 1)&.to_i

    # We have custom descriptions for certain Ebooks because we don't like the ones that come with the Ebook.
    # Note: there needs to be a better way to manage these.
    story_description = case series_name
                        when "Tarrin Kael Firestaff Series"
                          "Book #{series_book_order} in the #{series_name}, an epic fantasy story series, where Tarrin Kael, a quiet and unassuming young human boy grows into one of the most powerful beings in the world, able to challenge even the gods!"
                        end

    intro_text = nil
    outro_text = nil
    copyright_notice = "Copyright #{author_text}"

    chapter_contents = []
    chapter_files = content_xml_doc.xpath("//manifest/item")&.select do |item|
      item.attribute("href").inner_text.match(/\d{3,3}\.html$/)
    end&.map do |item|
      item.attribute("href").inner_text
    end

    # Ignore the first title 000 file
    chapter_files.shift

    chapter_files.each do |chapter_file|
      chapter_file = File.join(folder, chapter_file)
      chapter_doc = File.open(chapter_file) { |f| Nokogiri::HTML(f) }

      chapter_title = nil
      ["h1", "h2", "h3", "h4", "h5"].reverse.each do |header_selector|
        chapter_title_node = chapter_doc.css(header_selector)[0]
        if chapter_title_node
          chapter_title = chapter_title_node.inner_text.squish
          break
        end
      end

      # Find all p nodes
      chapter_paragraph_nodes = chapter_doc.css("p")
      chapter_paragraph_nodes = chapter_paragraph_nodes.reject do |node|
        text_content = node.inner_text.squish
        text_content.match(/EoF$/) ||
          text_content.match(/Title.*?Epilogue/) ||
          text_content.match(/Go to Chapter/) ||
          text_content.empty?
      end

      # Now replace <span class="bold"> and <span class="italic"> with semantic versions
      chapter_paragraph_nodes.each do |paragraph_node|
        paragraph_node.remove_attribute("class")
        paragraph_node.xpath(".//span[@class='bold']").each do |bold_span|
          bold_span.name = "strong"
          bold_span.remove_attribute("class")
        end
        paragraph_node.xpath(".//span[@class='italic']").each do |italic_span|
          italic_span.name = "em"
          italic_span.remove_attribute("class")
        end
      end

      chapter_content = chapter_paragraph_nodes.map(&:to_html).join("\n")
      chapter_content = ActionController::Base.helpers.sanitize(chapter_content, tags: %w(b i em strong p))

      chapter_contents << {title: chapter_title, content: chapter_content}
    end

    @author = author_text
    @series = series_name
    @stories = [{
      name: story_name,
      description: story_description,
      intro: intro_text,
      outro: outro_text,
      copyright_notice: copyright_notice,
      series_book_title: series_book_title,
      series_book_order: series_book_order,
      chapters: chapter_contents,
    }]

    completed!
  rescue Exception => e
    failed!(exception: e)
  end
end
