require 'rubygems'
require 'nokogiri'
require 'json'

def tokens_to_measures(tokens)
	raise "missing start bar" if tokens[0] != "["
	tokens.shift
	sections = []
	measures = []
	measure = []
	print tokens
	while tokens.length > 0 do 
		t = tokens.shift
		# barline, new measure.
		if t == "|"
			next if measure == []
			measures << measure.clone
			measure = []
		elsif(t == "||")
			sections << measures.clone
			measures = []
		else
			measure << t
		end
	end
	sections << measures if measures != []
	sections
end

def chart_music_to_json(chart_music)
	clean = chart_music.lines.to_a[1..-1].join # rm first line, all whitespace.
	# Don't parse repeats yet.
	raise "Won't parse repeats" if (chart_music.include? "1" or chart_music.include? "2" or chart_music.include? ":")
	# make a stack.
	tokens = clean.split(" ")
	return tokens_to_measures(tokens)
end

def chart_data_to_json(song_chart)
	clean = song_chart.to_s.sub("<pre>","").sub("</pre>","")
	key_header_idx = clean.index("Key of")
	raise "no key found" if !key_header_idx
	clean = clean[key_header_idx..-1]
	meta = clean.lines.first.gsub(/\(.+?\)/,"").split(" ")
	json = {}
	raise "malformed meta" if meta.size != 4
	json["key"] = meta[2]
	json["time"] = meta[3]
	json["sections"] = chart_music_to_json(clean)
end

def chart_html_to_json(html)
	page = Nokogiri::HTML(html)
	song_name = page.css("body").css("h4").to_s.sub("<h4>","").sub("</h4>","")
	song_data = page.css("body").css("pre")
	json_out = {}
	json_out["song_name"] = song_name.to_s.strip
	json_out["song_data"] = chart_data_to_json(song_data)
	json_out.to_json
end
#puts chart_html_to_json(File.read("charts_html/a1.html"))

fail = 0
ok = 0
Dir.entries("charts_html/").each do |html_file|
	next if html_file == "." || html_file == ".."

	begin
		html = File.read("charts_html/#{html_file}")
		json = chart_html_to_json(html)
	rescue StandardError => e  
		puts "for #{html_file}"
		puts e
		fail += 1
		next
	end
	ok += 1
	File.write("charts_json/#{html_file.split(".")[0]}.json",json)
end
puts "ok #{ok} fail #{fail}"