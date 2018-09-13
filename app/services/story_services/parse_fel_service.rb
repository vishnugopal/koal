# encoding: UTF-8

require_relative "../support/service"

#
# This isn't the best code I've written, but parsing Fel's Word HTML output
# is an excercise in despair. I've tried to identify common patterns when
# possible!
#
class StoryServices::ParseFelService < Koal::Service
  attr_reader :author, :series, :stories

  def call(folder:)
    book_pattern = "*by_Fel_c.htm"
    books_html = Dir[File.join(folder, book_pattern)].sort

    book_html = books_html.first
    book_doc = File.open(book_html) { |f| Nokogiri::HTML(f) }

    series_and_book_xpath = "//div/p[position() >= 0 and position() < 5]"
    data = book_doc.xpath(series_and_book_xpath)[0..3].map { |f| f.inner_text.squish }
    series_name = data[0].blank? ? "#{data[1]} #{data[2]}" : "#{data[0]} #{data[1]}"
    series_book_title = data[0].blank? ? data[3] : data[2]
    series_book_order = 1

    # Try finding the correct header node
    header_xpath = ""
    ["h1", "h2", "h3", "h4", "h5"].each do |header_selector|
      story_name_node = book_doc.xpath("//#{header_selector}[1]")[0]
      if story_name_node
        header_xpath = header_selector
        break
      end
    end
    story_name = book_doc.xpath("//#{header_xpath}[1]")[0].inner_text.chop.gsub("©", "")
    author_text = book_doc.xpath("//#{header_xpath}[1]/following-sibling::p[1]").inner_text.squish.gsub("by ", "")

    # The book downloads don't have descriptions themselves, so we've written our own descriptions based on the series.
    story_description = ""
    if (File.basename(book_html).to_s =~ /Firestaff_Collection/).present?
      story_description = "Book #{series_book_order} in the #{series_name}, an epic fantasy story series, where Tarrin Kael, a quiet and unassuming young human boy grows into one of the most powerful beings in the world, able to challenge even the gods!"
    elsif (File.basename(book_html).to_s =~ /Pyrosian_Chronicles/).present?
      story_description = "Book #{series_book_order} in the #{series_name}. Tarrin Kael's next adventure takes him beyond Sennadar, and helps him understand how powerful and how unique he truly is."
    end

    copyright_notice = "Copyright #{author_text}"

    # Find chapter counts by iterating over
    chapter_iterator = 1
    loop do
      chapter_count_xpath = "//a[@name='CH#{chapter_iterator.to_s.rjust(3, "0")}'][1]"
      chapter_count_node = book_doc.xpath(chapter_count_xpath)[0]
      break unless chapter_count_node
      chapter_iterator += 1
    end
    chapter_count = chapter_iterator - 1

    chapter_contents = []
    outro_text = nil
    1.upto(chapter_count) do |chapter_number|
      chapter_title_xpath = "//a[@name='CH#{chapter_number.to_s.rjust(3, "0")}']/parent::p/following-sibling::#{header_xpath}[1]"
      chapter_title_node = book_doc.xpath(chapter_title_xpath)[0]
      unless chapter_title_node
        chapter_title_xpath = chapter_title_xpath = "//a[@name='CH#{chapter_number.to_s.rjust(3, "0")}']/parent::#{header_xpath}[1]"
        chapter_title_node = book_doc.xpath(chapter_title_xpath)[0]
      end

      chapter_title = chapter_title_node&.inner_text

      next_chapter_number = chapter_number + 1
      next_chapter_last_paragraph_xpath = "//a[@name='CH#{next_chapter_number.to_s.rjust(3, "0")}']/parent::p/preceding-sibling::p[1]"
      next_chapter_last_paragraph_node = book_doc.xpath(next_chapter_last_paragraph_xpath)[0]

      # i.e. if it's the last chapter, we process for outro instead
      if chapter_number == chapter_count
        chapter_title_xpath = "//a[@name='CH#{chapter_number.to_s.rjust(3, "0")}']/parent::p"
        chapter_title_node = book_doc.xpath(chapter_title_xpath)[0]
        next_chapter_last_paragraph_xpath = "(//a[@href='#CH001'])[last()]/ancestor::p/preceding-sibling::p[3]"
        next_chapter_last_paragraph_node = book_doc.xpath(next_chapter_last_paragraph_xpath)[0]
      end

      paragraph_index = 0
      chapter_content = ""

      # Outro sometimes has additional content as headers
      if chapter_number == chapter_count
        chapter_content_node = chapter_title_node.xpath("./following-sibling::#{header_xpath}")[0]

        if chapter_content_node and chapter_content_node.inner_text.squish.present?
          chapter_content << chapter_content_node.inner_text.squish << "\n"
        end
      end

      loop do
        paragraph_index += 1
        chapter_content_node = chapter_title_node.xpath("./following-sibling::p[#{paragraph_index}]")[0]

        unless chapter_content_node.inner_text.squish.empty?
          if chapter_number == chapter_count
            chapter_content << chapter_content_node.inner_text.squish << "\n"
          else
            chapter_content << chapter_content_node.to_xhtml.squish.gsub("&#13;", "") << "\n"
          end
        end

        break if chapter_content_node == next_chapter_last_paragraph_node
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
