require_relative "../support/service"

class StoryServices::ImportFelService < Koal::Service
  def call(folder:)
    book_pattern = "*by_Fel_c.htm"
    books_html = Dir[File.join(folder, book_pattern)].sort

    book_html = books_html.first
    book_doc = File.open(book_html) { |f| Nokogiri::HTML(f) }

    series_and_book_xpath = "//div/p[position() >= 0 and position() < 5]"
    series_name = book_doc.xpath(series_and_book_xpath)[1..2].map { |f| f.inner_text }.join
    series_book_title = book_doc.xpath(series_and_book_xpath)[3].inner_text.squish
    series_book_order = 1

    story_name = book_doc.xpath("//h5[1]")[0].inner_text.chop
    author_text = book_doc.xpath("//h5[1]/following-sibling::p[1]").inner_text.squish.gsub("by ", "")

    chapter_number = 1
    chapter_title_xpath = "//a[@name='CH#{chapter_number.to_s.rjust(3, "0")}']/parent::p/following-sibling::h5[1]"
    chapter_title_node = book_doc.xpath(chapter_title_xpath)
    chapter_title = chapter_title_node.inner_text

    next_chapter_number = chapter_number + 1
    next_chapter_last_paragraph_xpath = "//a[@name='CH#{next_chapter_number.to_s.rjust(3, "0")}']/parent::p/preceding-sibling::p[1]"
    next_chapter_last_paragraph_node = book_doc.xpath(next_chapter_last_paragraph_xpath)[0]

    paragraph_index = 1
    chapter_content_node = chapter_title_node.xpath("./following-sibling::p[#{paragraph_index}]")[0]
    chapter_contents = ""
    until chapter_content_node == next_chapter_last_paragraph_node
      chapter_contents << chapter_content_node.to_xhtml.squish.gsub(' class="MsoNormal"', "").gsub("<p> ", "<p>").gsub("&#13;", "") << "\n"
      paragraph_index += 1
      chapter_content_node = chapter_title_node.xpath("./following-sibling::p[#{paragraph_index}]")[0]
    end

    puts chapter_contents

    completed!
  rescue Exception => e
    failed!(exception: e)
  end
end
