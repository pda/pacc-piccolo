require 'rubygems'
require 'yaml'
require 'haml'
require 'rdiscount'

module Piccolo

  class Server
    def call(env)
      request = Rack::Request.new env

      begin
        raise HttpError.new(405, 'Method not allowed') unless request.get? or request.head?
        status, content = 200, dispatch(request)
      rescue HttpError
        status, content = $!.code, HamlView.new(:error, :error => $!).to_html
      end

      headers = {
        'Content-Length' => content.length.to_s,
        'Content-Type' => 'text/html'
      }

      [status, headers, request.head? ? '' : content]
    end

    private

    def dispatch(request)
      if request.path == '/'
        HamlView.new(:home, :posts => PostCollection.new).to_html
      elsif /^\/(\d{4})\/(\d{2})\/([\w-]+)/.match(request.path)
        post = PostCollection.new.post($1, $2, $3)
        data = post.meta.merge(:post => post, :content => post.content)
        HamlView.new(:post, data).to_html
      else
        raise HttpError.new(404, 'Path Not Found')
      end
    end
  end

  class HamlView
    OPTIONS = { :dir => 'templates', :format => :html5 }
    def initialize(template, data = {})
      @template, @data = template, data
    end
    def to_html
      render_haml(:base, @data, render_haml(@template, @data))
    end
    def render_haml(name, data, content = nil)
      path = "#{OPTIONS[:dir]}/#{name}.haml"
      Haml::Engine.new(File.read(path), OPTIONS).render(
        nil,
        data.merge(:content => content)
      )
    end
  end

  class Post
    attr_reader :meta, :content, :title, :date, :url
    def initialize(path)
      begin
        yaml, markdown = File.read(path).split(/\n\n/, 2)
      rescue Errno::ENOENT
        raise HttpError.new(404, 'Post Not Found')
      end
      @path = path
      @meta, @content = YAML::load(yaml), RDiscount.new(markdown).to_html
      @title, @date = @meta.values_at('title', 'date')
    end
    def url
      @path =~ /\/(\d{4})-(\d{2})-([\w-]+).txt$/
      "/#{$1}/#{$2}/#{$3}"
    end
  end

  class PostCollection
    include Enumerable
    DIR = 'posts'
    def each
      Dir.glob("#{DIR}/*.txt").each { |path| yield Post.new(path) }
    end
    def post(year, month, stub)
      Post.new('%s/%04d-%02d-%s.txt' % [DIR, year, month, stub])
    end
  end

  class HttpError < StandardError
    attr_reader :code, :message
    def initialize(code, message = nil)
      @code, @message = code, message
    end
  end

end
