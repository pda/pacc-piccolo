#!/usr/bin/env ruby

require 'rubygems'
require 'json'

JSON.parse(File.read('posts.couchdb'))['rows'].map{|r| r['value']}.each do |row|
  File.open("posts/#{row['_id']}.txt", 'w') do |f|
    f.puts '---'
    if row['title'].match(/: /)
      f.puts "title: \"#{row['title']}\""
    else
      f.puts "title: #{row['title']}"
    end
    f.puts "time: #{row['timecreated']}"
    f.puts "modified: #{row['timemodified']}" if row['timemodified'] != row['timecreated']
    f.puts 'uid: ' + row['uid']
    f.puts
    f.puts row['content'].gsub("\r\n", "\n")
  end
end
