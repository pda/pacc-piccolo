%w{ time rubygems yaml haml rdiscount builder }.each{ |r| require r }

module Piccolo

  class Entry
    attr_reader :meta, :content, :title, :time, :url
    def initialize(path)
      begin
        yaml, markdown = File.read(path).split(/\n\n/, 2)
      rescue Errno::ENOENT
        raise HttpError.new(404, '%s Not Found' % self.type)
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
  end

  class PostCollection < EntryCollection
    def initialize
      super 'posts', Post
    end
    def post(year, month, stub)
      Post.new('%s/%04d-%02d-%s.txt' % [@dir, year, month, stub])
    end
  end

  class LinkCollection < EntryCollection
    def initialize
      super 'links', Link
    end
    def link(year, month, stub)
      Link.new('%s/%04d-%02d-%s.txt' % [@dir, year, month, stub])
    end
  end

  class HttpError < StandardError
    attr_reader :code, :message
    def initialize(code, message = nil)
      @code, @message = code, message
    end
  end

end
