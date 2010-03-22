#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'yaml'

doc = Nokogiri::HTML(File.open('delicious.htm', 'r'))

bookmarks = []

doc.css('dt').each do |dt|

  a = dt.child

  bookmark = {
    :data => {
      'url' => a[:href],
      'time' => Time.at(a[:add_date].to_i),
      'tags' => a[:tags].gsub(',', ' '),
      'title' => a.text,
    }
  }

  if (dd = dt.next_element) && (dd.node_name == 'dd')
    bookmark[:description] = dd.text
  end

  bookmarks << bookmark

end

bookmarks.each do |bookmark|
  time = bookmark[:data]['time']
  title = bookmark[:data]['title']
  slug = title.downcase.split(/\W+/)[0...8].reject{|x|x=~/^[\w]?$/}.join('-')
  path = 'links/%04d-%02d-%s.txt' % [time.year, time.month, slug]
  File.open(path, 'w') do |f|
    f.puts bookmark[:data].to_yaml
    f.puts
    f.puts bookmark[:description] if bookmark[:description]
  end
end
