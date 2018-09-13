require_relative "../support/service"

class StoryServices::ParseFelService < Koal::Service
  attr_reader :author, :series, :stories

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

    # The book downloads don't have descriptions themselves, so we've written our own descriptions based on the series.
    story_description = ""
    if (File.basename(book_html).to_s =~ /Tarrin_Kael/).present? #Tarrin Kael's Sennadar Series
      story_description = "Book #{series_book_order} in the #{series_name}, an epic fantasy story series, where Tarrin Kael, a quiet and unassuming young human boy grows into one of the most powerful beings in the world, able to challenge even the gods!"
    end

    copyright_notice = "Copyright #{author_text}"

    chapter_count_xpath = "//a[@href='#TITLE']/following-sibling::a[last()]"
    chapter_count_node = book_doc.xpath(chapter_count_xpath)[0]
    chapter_count = chapter_count_node["href"].gsub("#CH", "").to_i

    chapter_contents = []
    outro_text = nil
    1.upto(chapter_count) do |chapter_number|
      chapter_title_xpath = "//a[@name='CH#{chapter_number.to_s.rjust(3, "0")}']/parent::p/following-sibling::h5[1]"
      chapter_title_node = book_doc.xpath(chapter_title_xpath)[0]
      chapter_title = chapter_title_node&.inner_text

      next_chapter_number = chapter_number + 1
      next_chapter_last_paragraph_xpath = "//a[@name='CH#{next_chapter_number.to_s.rjust(3, "0")}']/parent::p/preceding-sibling::p[1]"
      next_chapter_last_paragraph_node = book_doc.xpath(next_chapter_last_paragraph_xpath)[0]

      # i.e. if it's the last chapter, we process for outro instead
      if chapter_number == chapter_count
        chapter_title_xpath = "//a[@name='CH#{chapter_number.to_s.rjust(3, "0")}']/parent::p"
        chapter_title_node = book_doc.xpath(chapter_title_xpath)[0]
        next_chapter_last_paragraph_xpath = "(//a[@href='#CH#{chapter_number.to_s.rjust(3, "0")}'])[last()]/ancestor::p/preceding-sibling::p[2]"
        next_chapter_last_paragraph_node = book_doc.xpath(next_chapter_last_paragraph_xpath)[0]
      end

      paragraph_index = 1
      chapter_content_node = chapter_title_node.xpath("./following-sibling::p[#{paragraph_index}]")[0]
      chapter_content = ""
      until chapter_content_node == next_chapter_last_paragraph_node
        unless chapter_content_node.inner_text.squish.empty?
          chapter_content << chapter_content_node.to_xhtml.squish.gsub("&#13;", "") << "\n"
        end
        paragraph_index += 1
        chapter_content_node = chapter_title_node.xpath("./following-sibling::p[#{paragraph_index}]")[0]
      end

      chapter_content = ActionController::Base.helpers.sanitize(chapter_content, tags: %w(b i em strong p)).gsub('p class="MsoNormal"', "p").gsub("<p> ", "<p>")

      if chapter_number == chapter_count
        outro_text = "<p>" + ActionController::Base.helpers.sanitize(chapter_content, tags: %w()).squish + "</p>"
      else
        chapter_contents << {title: chapter_title, content: chapter_content}
      end
    end

    @author = author_text
    @series = series_name
    @stories = [{
      name: story_name,
      description: story_description,
      intro: nil,
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
