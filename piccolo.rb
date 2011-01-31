%w{ time yaml rdiscount }.each{ |r| require r }

module Piccolo

  class Entry
    attr_reader :meta, :content, :title, :time, :url
    def initialize(path)
      begin
        yaml, markdown = File.open(path, "r:UTF-8").read.split(/\n\n/, 2)
      rescue Errno::ENOENT
        raise NameError, '%s not found' % self.type
      end
      @path = path
      @meta = YAML::load yaml
      @content = RDiscount.new(markdown).to_html
      @title, @time = @meta['title'], Time.parse(@meta['time'].to_s)
    end
    def date_formatted
      @time.strftime('%d %B %Y').sub(/^0/, '')
    end
    def <=>(other)
      other.time <=> time
    end
    def type
      self.class.name.split('::').last.downcase
    end
  end

  class Post < Entry
    def url
      @path =~ /\/(\d{4})-(\d{2})-([\w-]+).txt$/
      "/#{$1}/#{$2}/#{$3}"
    end
  end

  class Link < Entry
    def url
      @meta['url']
    end
  end

  class EntryCollection
    include Enumerable
    def initialize(dir, klass)
      @dir = dir
      @klass = klass
    end
    def each
      Dir.glob("#{@dir}/*.txt").reverse.each { |path| yield @klass.new(path) }
    end
    def empty?
      to_a.empty?
    end
    def find(year, month, stub)
      @klass.new('%s/%04d-%02d-%s.txt' % [@dir, year.to_i, month.to_i, stub])
    end
  end

  class PostCollection < EntryCollection
    def initialize
      super 'posts', Post
    end
  end

  class LinkCollection < EntryCollection
    def initialize
      super 'links', Link
    end
  end

  module_function

  def entries_all
    (PostCollection.new.to_a + LinkCollection.new.to_a).sort
  end

end
