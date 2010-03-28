#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'yaml'
require 'time'

doc = Nokogiri::XML(open('./delicious-links.xml').read, nil, 'UTF-8')

doc.css('post').each do |post|

  data = {
    'title' => post['description'],
    'url' => post['href'],
    'time' => Time.parse(post['time']).localtime,
    'tags' => post['tag'],
  }

  time = data['time']
  title = data['title']
  description = post['extended']

  slug = title.downcase.split(/\W+/)[0...8].reject{|x|x=~/^[\w]?$/}.join('-')
  path = 'links/%04d-%02d-%s.txt' % [time.year, time.month, slug]

  File.open(path, 'w') do |f|
    f.puts data.to_yaml
    f.puts
    f.puts description unless description.empty?
  end

end
