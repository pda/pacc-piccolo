# thanks to http://github.com/cloudhead/toto
xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title 'paul.annesley.cc'
  xml.id 'http://paul.annesley.cc/'
  xml.link :rel => 'self', :href => 'http://paul.annesley.cc/feed'
  xml.updated @entries.first.time.gmtime.iso8601 unless @entries.empty?
  xml.author { xml.name 'Paul Annesley' }
  @entries.to_a[0...10].each do |entry|
    xml.entry do
      xml.id entry.meta['uid'] || entry.url
      xml.published entry.time.gmtime.iso8601
      xml.updated entry.time.gmtime.iso8601
      xml.title entry.title
      xml.link 'rel' => 'alternate', 'href' => entry.url
      xml.content entry.content, "type" => "html"
    end
  end
end
