require 'rubygems'
require 'restclient'
require 'xmlsimple'

iregex = /http:\/\/(i\.){0,1}(minus|imgur).com\/[0-9a-zA-Z]+(\.jpg|\.gif|\.png){0,1}/i
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
    img = (/(jpg|gif|png)$/i).match l
    if !img
      [".jpg", ".gif", ".png"].each { |ending|
        puts "  Checking #{l}"
        candidate = l.to_s + ending
        i = File.join destination, File.basename(candidate)
        already_have = File.exists? i
        if already_have
          puts "Skipping write of #{i}"
          break
        else
          RestClient.get(candidate) { |response, request, result|
            next if response.code.to_s.start_with? "404"
            File.open(i, 'w') { |f| f.write response }
            puts "Writing #{i}"
            newfiles = newfiles + 1
            break
          }
        end
      }
    else
      i = File.join destination, File.basename(l)
      already_have = File.exists? i
      if already_have
        puts "Skipping write of #{i}"
      else
        File.open(i, 'w') { |f| f.write(RestClient.get(l)) }
        puts "Writing #{i}"
        newfiles = newfiles + 1
      end
    end
  }
end

puts "\nWrote #{newfiles} new files."
