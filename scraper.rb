require 'rubygems'
require 'restclient'
require 'xmlsimple'

iregex = /http:\/\/i.imgur.com\/[0-9a-zA-Z]+\.(jpg|gif|png)/i
newfiles = 0

ARGV.each do |subreddit|
  destination = subreddit

  # get the rss feed
  data = RestClient.get "http://www.reddit.com/r/#{subreddit}/.rss"
  if data.code != 200
    puts "Invalid subreddit (url)"
    exit
  end
  # get xml from the data
  begin
    xml = XmlSimple.xml_in(data)
  rescue
    puts "XML for subreddit #{subreddit} was invalid."
    exit
  end

  # make the empty directory pics
  begin
    FileUtils.mkdir destination
  rescue
  end

  # get all the links
  links = xml["channel"][0]["item"].collect { |i|
    iregex.match(i["description"][0])
  }

  # download all the files
  links.each { |lnk|
    next if lnk.nil?
    l = lnk[0]
    i = File.join destination, File.basename(l)
    already_have = File.exists? i
    if already_have
      puts "Skipping write of #{i}"
    else
      File.open(i, 'w') { |f| f.write(RestClient.get(l)) }
      puts "Writing #{i}"
      newfiles = newfiles + 1
    end
  }
end

puts "\nWrote #{newfiles} new files."
