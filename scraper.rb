require 'rubygems'
require 'restclient'
require 'xmlsimple'

iregex = /http:\/\/(i\.){0,1}(minus|imgur).com\/([0-9a-zA-Z]){3,}(\.jpg|\.gif|\.png){0,1}/i
newfiles = 0

ARGV.each do |subreddit|
  destination = subreddit

  # get the rss feed
  begin
    data = RestClient.get "http://www.reddit.com/r/#{subreddit}/.rss"
    if data.code != 200
      puts "Invalid subreddit (url)"
      next
    end
  rescue
    puts "Couldn't get #{subreddit}/.rss"
    next
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
        gstr = "#{File.join(destination, File.basename(l.to_s))}*"
	puts "   gstr: #{gstr}"
        g = Dir.glob gstr
        already_have = g.size > 0
        if already_have
          puts "Skipping write of #{i}"
          break
        else
          begin
            RestClient.get(candidate) { |response, request, result|
              next unless response.code.to_s.start_with? "200"
              File.open(i, 'w') { |f| f.write response }
              puts "Writing #{i}"
              newfiles = newfiles + 1
            }
          rescue
            next
          end
        end
      }
    else
      i = File.join destination, File.basename(l)
      already_have = File.exists? i
      if already_have
        puts "Skipping write of #{i}"
      else
        begin
          File.open(i, 'w') { |f| f.write(RestClient.get(l)) }
          puts "Writing #{i}"
          newfiles = newfiles + 1
        rescue
        end
      end
    end
  }
end

puts "\nWrote #{newfiles} new files."
