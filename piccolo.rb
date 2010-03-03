require 'rubygems'
require 'yaml'
require 'haml'
require 'rdiscount'

module Piccolo

  class Server

    HamlOptions = { :format => :html5 }

    def call(env)
      request = Rack::Request.new env

      begin
        raise HttpError.new(405, 'Method not allowed') unless request.get? or request.head?
        status, content = 200, dispatch(request)
      rescue HttpError
        status, content = [$!.code, $!.message.to_s + "\n"]
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
        posts = Dir['posts/*.txt'].map do |file|
          Post.new(file)
        end
        render_page :home, nil, :title => 'Home', :posts => posts
      elsif /^\/(\d{4})\/(\d{2})\/([\w-]+)/.match(request.path)
        post = Post.new("posts/#{$1}-#{$2}-#{$3}.txt")
        render_page :post, post.content, post.data.merge({:post => post})
      else
        raise HttpError.new(404, 'page not found')
      end
    end

    def render_page(type, content = nil, data = {})
      render_haml(:base, data, render_haml(type, data, content))
    end

    def render_haml(name, data, content)
      Haml::Engine.new(
        File.read("templates/#{name}.haml"),
        HamlOptions
      ).render(
        nil,
        data.merge({:content => content})
      )
    end
  end

  class Post
    attr_reader :data, :content, :title, :date
    def initialize(path)
      begin
        yaml, markdown = File.read(path).split(/\n\n/, 2)
        @path = path
        @data, @content = YAML::load(yaml), RDiscount.new(markdown).to_html
        @title, @date = @data.values_at('title', 'date')
      rescue Errno::ENOENT
        raise HttpError.new(404, "Not Found: #{path}")
      end
    end
    def url
      @path =~ /^posts\/(\d{4})-(\d{2})-([\w-]+).txt$/
      "/#{$1}/#{$2}/#{$3}"
    end
  end

  class HttpError < StandardError
    attr_reader :code, :message
    def initialize(code, message = nil)
      @code, @message = code, message
    end
  end

end
