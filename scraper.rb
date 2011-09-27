require 'rubygems'
require 'restclient'
require 'xmlsimple'
require 'pony'

# First argument should be a subreddit
subreddit = ARGV[0]
# destination  is the second argument
destination = ARGV[1]

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
  puts "XML was invalid."
  exit
end

# make the empty directory pics
FileUtils.rm_rf 'pics' if File.exist? 'pics'
FileUtils.mkdir 'pics'

# get all the links
links = xml["channel"][0]["item"].collect { |i|
	i["description"][0].scan(/http:\/\/i.imgur.com\/[0-9a-zA-Z]+\.jpg/).first
}

# download all the files
links.each { |l|
	File.open('pics/' + File.basename(l), 'w') { |f| f.write(RestClient.get(l)) } unless l.nil?
}

# put the files into an array to attach to the file
files = {}
Dir.entries('pics').each { |f|
	files[File.basename(f)] = File.read('pics/' + f) unless f == "." || f == ".."
}

# send the email
begin
	sent = Pony.mail(
		:to => destination,
		:from => destination,
		:subject => 'Reddit Scraper', 
		:body => 'Here are your wonderful files...',
		:attachments => files
	)
rescue
	puts "Email wasn't sent." if !sent
end

# remove the directory
FileUtils.rm_rf 'pics'
