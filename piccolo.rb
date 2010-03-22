%w{ rubygems yaml haml rdiscount builder }.each{ |r| require r }

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
      elsif %w{ /articles/feed /feed /feed/atom /feed/ }.member? request.path
        posts, links = PostCollection.new, LinkCollection.new
        entries = (posts.to_a + links.to_a).sort

        # thanks to http://github.com/cloudhead/toto
        feed = Builder::XmlMarkup.new :indent => 2
        feed.instruct!
        feed.feed "xmlns" => "http://www.w3.org/2005/Atom" do
          feed.title 'paul.annesley.cc'
          feed.id 'http://paul.annesley.cc/'
          feed.link :rel => 'self', :href => 'http://paul.annesley.cc/feed'
          feed.link :rel => 'alternate', :href => 'http://paul.annesley.cc/'
          feed.updated Time.parse(posts.first.date.asctime).gmtime.iso8601 unless posts.empty?
          feed.author { feed.name 'Paul Annesley' }

          posts.each do |post|
            feed.entry do
              feed.id post.meta['uid']
              feed.published Time.parse(post.date.asctime).gmtime.iso8601
              feed.title post.title
              feed.link 'rel' => 'alternate', 'href' => 'http://paul.annesley.cc' + post.url
              feed.content post.content, "type" => "html"
            end
          end
        end
        response['Content-Type'] = 'application/atom+xml'
        response.body = feed.to_xml

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
    attr_reader :meta, :content, :title, :date, :url
    def initialize(path)
      begin
        yaml, markdown = File.read(path).split(/\n\n/, 2)
      rescue Errno::ENOENT
        raise HttpError.new(404, '%s Not Found' % self.type)
      end
      @path = path
      @meta = YAML::load yaml
      @content = RDiscount.new(markdown).to_html
      @title, @date = @meta['title'], Date.parse(@meta['date'])
    end
    def date_formatted
      @date.strftime('%d %B %Y').sub(/^0/, '')
    end
    def <=>(other)
       other.date <=> date
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
