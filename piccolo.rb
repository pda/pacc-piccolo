%w{ time rubygems yaml haml rdiscount builder }.each{ |r| require r }

module Piccolo

  class Server

    def call(env)
      begin
        dispatch(Rack::Request.new(env), Rack::Response.new).finish
      rescue HttpError
        Rack::Response.new(HamlView.new(:error, :error => $!).to_html, $!.code).finish
      end
    end

    def dispatch(request, response)
      unless request.get? or request.head?
        raise HttpError.new(405, 'Method not allowed')
      end

      # index
      if request.path == '/'
        posts, links = PostCollection.new, LinkCollection.new
        entries = (posts.to_a + links.to_a).sort
        response.body = HamlView.new(:home, :entries => entries).to_html

      # feed
      elsif request.path == '/feed'
        posts, links = PostCollection.new, LinkCollection.new
        entries = (posts.to_a + links.to_a).sort
        if ENV['FEED_EPOCH']
          entries.delete_if { |e| e.time < Time.parse(ENV['FEED_EPOCH']) }
        end

        # thanks to http://github.com/cloudhead/toto
        feed = Builder::XmlMarkup.new :indent => 2
        feed.instruct!
        response.body = feed.feed "xmlns" => "http://www.w3.org/2005/Atom" do
          feed.title 'paul.annesley.cc'
          feed.id 'http://paul.annesley.cc/'
          feed.link :rel => 'self', :href => 'http://paul.annesley.cc/feed'
          feed.updated entries.first.time.gmtime.iso8601 unless entries.empty?
          feed.author { feed.name 'Paul Annesley' }
          entries.to_a[0...10].each do |entry|
            feed.entry do
              feed.id entry.meta['uid'] || entry.url
              feed.published entry.time.gmtime.iso8601
              feed.updated entry.time.gmtime.iso8601
              feed.title entry.title
              feed.link 'rel' => 'alternate', 'href' => entry.url
              feed.content entry.content, "type" => "html"
            end
          end
        end
        response['Content-Type'] = 'application/atom+xml'

      # page
      elsif /^\/([\w-]+)$/.match(request.path)
        response.body = HamlView.new(:page, :page => Page.new($1)).to_html

      # post
      elsif /^\/(\d{4})\/(\d{2})\/([\w-]+)/.match(request.path)
        post = PostCollection.new.post($1, $2, $3)
        data = post.meta.merge(:post => post, :content => post.content)
        response.body = HamlView.new(:post, data).to_html

      else
        raise HttpError.new(404, 'Path Not Found')
      end

      response
    end
  end

  class HamlView
    OPTIONS = { :dir => 'templates', :format => :html5 }
    def initialize(template, data = {})
      @template, @data = template, data
    end
    def to_html
      render_haml(path(:base), @data, render_haml(path(@template), @data))
    end
    def render_haml(path, data = {}, base_content = nil)
      Haml::Engine.new(File.read(path), OPTIONS).render(
        nil,
        data.merge(:base_content => base_content)
      )
    end
    private
    def path(name)
      "#{OPTIONS[:dir]}/#{name}.haml"
    end
  end

  class Page
    DIR = 'pages'
    def initialize(name)
      begin
        @name = name
      rescue Errno::ENOENT
        raise HttpError.new(404, 'Post Not Found')
      end
    end
    def content
      # TODO: don't abuse HamlView
      HamlView.new(nil, nil).render_haml(
        "#{DIR}/#{@name}.haml"
      )
    end
  end

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

  class PostCollection
    include Enumerable
    DIR = 'posts'
    def each
      Dir.glob("#{DIR}/*.txt").reverse.each { |path| yield Post.new(path) }
    end
    def empty?
      to_a.empty?
    end
    def post(year, month, stub)
      Post.new('%s/%04d-%02d-%s.txt' % [DIR, year, month, stub])
    end
  end

  class LinkCollection
    include Enumerable
    DIR = 'links'
    def each
      Dir.glob("#{DIR}/*.txt").reverse.each { |path| yield Link.new(path) }
    end
    def link(year, month, stub)
      Link.new('%s/%04d-%02d-%s.txt' % [DIR, year, month, stub])
    end
  end

  class HttpError < StandardError
    attr_reader :code, :message
    def initialize(code, message = nil)
      @code, @message = code, message
    end
  end

end
