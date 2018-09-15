# encoding: UTF-8

require_relative "../support/service"

class StoryServices::ParseFelEPUBService < Koal::Service
  attr_reader :author, :stories

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

    # clean up copyright character and author atribution
    if story_name[-1] == "©"
      story_name.chop!
    end
    story_name.gsub!(/by .*?$/i, "")&.squish!

    series_book_title, story_name = story_name.split(" - ")
    series_book_title&.squish!
    series_book_title&.gsub!(series_name, "")&.squish!
    story_name&.squish!
    series_book_order = series_book_title.match(/Book (\d{1,2})/)&.public_send(:[], 1)&.to_i

    # We have custom descriptions for certain Ebooks because we don't like the ones that come with the Ebook.
    # Note: there needs to be a better way to manage these.
    story_description = case series_name
                        when "Tarrin Kael Firestaff Series"
                          "Book #{series_book_order} in the #{series_name}, an epic fantasy story series, where Tarrin Kael, a quiet and unassuming young human boy grows into one of the most powerful beings in the world, able to challenge even the gods!"
                        when "Tarrin Kael Pyrosian Chronicles"
                          "Book #{series_book_order} in the #{series_name}. Tarrin Kael's next adventure takes him beyond Sennadar, and helps him understand how powerful and how unique he truly is."
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

      # At times, chapter titles are presented with <p> tags too. :sigh:
      unless chapter_title
        chapter_title_nodes = chapter_doc.css("p span.bold")
        chapter_title_nodes.each do |node|
          node_text = node.inner_text.squish
          if node_text.match(/Chapter \d{1,3}/i) || node_text.match(/Epilogue/i)
            chapter_title = node_text
          end
        end
      end

      # Find all p nodes
      chapter_paragraph_nodes = chapter_doc.css("p")
      chapter_paragraph_nodes = chapter_paragraph_nodes.reject do |node|
        text_content = node.inner_text.squish
        filter_paragraphs_by_text_content(text_content: text_content)
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
      chapter_content = sanitize_to_html(html_content: chapter_content)

      # Extremely short chapters indicate it's an outro
      if chapter_content.length < 1000 && chapter_title.present?
        outro_text = chapter_title << " "
        outro_text << sanitize_to_text(html_content: chapter_content)

        # Now, weed out the case where chapter_content is empty
        outro_text.squish!
        if outro_text == chapter_title
          outro_text = nil
        end

        next
      elsif chapter_file.match(chapter_files.last)
        # If it's the last chapter, we might see outro appended to the end of it,
        # this is to check for that case. We extract the outro, and then remove it
        # from the chapter content, and instead present it separately as outro
        # for better presentation.

        last_a_node = chapter_doc.css("a").last

        # Make sure we've got a good link
        if last_a_node.inner_text.squish.include?("End of")
          link_href = last_a_node.attribute("href").inner_text.gsub(/^#/, "")
          outro_nodes = chapter_doc.xpath("//a[@id='#{link_href}']/ancestor::p/following-sibling::p")
          outro_nodes = outro_nodes.reject do |node|
            text_content = node.inner_text.squish
            filter_paragraphs_by_text_content(text_content: text_content)
          end

          # Strip this away from existing chapter_content
          outro_nodes_html_content = outro_nodes.map(&:to_html).join("\n")
          outro_nodes_html_content = sanitize_to_html(html_content: outro_nodes_html_content)
          chapter_content = chapter_content.gsub(outro_nodes_html_content, "")

          # Now return outro as text in a single paragraph
          outro_text = "<p>" + sanitize_to_text(html_content: outro_nodes_html_content) + "</p>"
        end
      end

      # We skip empty chapters. Yes, that happens a lot! :sigh:
      if chapter_title.present?
        chapter_contents << {title: chapter_title, content: chapter_content}
      end
    end

    @author = author_text
    @stories = [{
      name: story_name,
      description: story_description,
      intro: intro_text,
      outro: outro_text,
      copyright_notice: copyright_notice,
      series_name: series_name,
      series_book_title: series_book_title,
      series_book_order: series_book_order,
      chapters: chapter_contents,
    }]

    completed!
  rescue Exception => e
    failed!(exception: e)
  end

  private

  def sanitize_to_html(html_content:)
    ActionController::Base.helpers.sanitize(html_content, tags: %w(b i em strong p)).squish.gsub("<p> ", "<p>")
  end

  def sanitize_to_text(html_content:)
    ActionController::Base.helpers.sanitize(html_content, tags: %w()).gsub(/\n/, " ")
  end

  def filter_paragraphs_by_text_content(text_content:)
    text_content.squish!
    text_content.match(/EoF$/) ||
      text_content.match(/^Title.*?Epilogue/i) ||
      text_content.match(/^Epilogue.*?Epilogue/i) ||
      text_content.match(/^Go to Chapter/i) ||
      text_content.match(/^Goto Chapter/i) ||
      text_content.match(/Epilogue.*?End of.*?$/i) ||
      text_content.match(/Title.*?End of.*?$/i) ||
      text_content.match(/^Title$/i) ||
      text_content.match(/^Epilogue$/i) ||
      text_content.match(/^To:.*?Title.*?ToC.*/) ||
      text_content.match(/^To:.*?Title.*?Epilogue.*/) ||
      text_content.match(/^(\d+\s*?)+$/i) ||
      text_content.match(/^(\d+\s*?)+.*?Epilogue$/i) ||
      text_content.empty?
  end
end
