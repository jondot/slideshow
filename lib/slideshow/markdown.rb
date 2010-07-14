module Slideshow
  module MarkdownEngines

  # sample how to use your own converter
  # configure in slideshow.yml
  # pandoc-ruby:
  #  converter: pandoc-ruby-to-s5
  
  def pandoc_ruby_to_s5( content )
    content = PandocRuby.new( content, {:from => :markdown, :to => :s5}, :smart ).convert
    content = content.gsub(/class="incremental"/,'class="step"')
    content = content.to_a[13..-1].join # remove the layout div
  end

  def pandoc_ruby_to_s5_incremental( content )
    content = PandocRuby.new( content, {:from => :markdown, :to => :s5 }, :incremental, :smart ).convert
    content = content.gsub(/class="incremental"/,'class="step"')
    content = content.to_a[13..-1].join # remove the layout div
  end


  def pandoc_ruby_to_html( content )
    content = PandocRuby.new( content, :from => :markdown, :to => :html ).convert
  end
  
  def pandoc_ruby_to_html_incremental( content )
    content = PandocRuby.new( content, :from => :markdown, :to => :html ).convert
    content = content.gsub(/<(ul|ol)/) do |match|
      "#{Regexp.last_match(0)} class='step'"
    end
    content
  end
  
  def rdiscount_to_html( content )
    RDiscount.new( content ).to_html
  end
  
  def rpeg_markdown_to_html( content )
    PEGMarkdown.new( content ).to_html
  end
  
  def maruku_to_html( content )
    Maruku.new( content, {:on_error => :raise} ).to_html
  end
  
  def bluecloth_to_html( content )
    BlueCloth.new( content ).to_html
  end
  
  def kramdown_to_html( content )
    Kramdown::Document.new( content ).to_html
  end

end   # module MarkdownEngines
end # module Slideshow

class Slideshow::Gen
  include Slideshow::MarkdownEngines
end