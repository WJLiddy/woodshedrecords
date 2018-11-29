require 'json'

def get_sample_data()
	titles = []
	sections = []
	Dir.entries("transposed_charts_json/").each do |file|
		next if file == "." || file == ".."
		song = JSON::parse(File.read("transposed_charts_json/"+file))
		titles << song["song_name"]
		sections << song["song_data"]
	end
	[titles,sections]
end

def markov_section(section)

end

def collect_sections(sections)

end