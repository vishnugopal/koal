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

    story_description = "Book 1 in the #{series_name}, an epic fantasy story series, where Tarrin Kael, a quiet and unassuming young human boy grows into one of the most powerful beings in the world, able to challenge even the gods!"

    intro_text = nil
    outro_text = nil
    copyright_notice = "Copyright #{author_text}"
    chapter_contents = []

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
