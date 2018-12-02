require 'json'

def get_sample_data()
	titles = []
	sections = []
	Dir.entries("transposed_charts_json/").each do |file|
		next if (file == "." || file == "..")
		song = JSON::parse(File.read("transposed_charts_json/"+file))
		titles << song["song_name"]
		sections << song["song_data"]
	end
	[titles,sections]
end

# Naive solution just stops when tonic is reached.
# Better solution uses a neural net.
def collect_sections(songs)
	section_lists = []
	songs.each do |song|
		song.each_with_index do |section,i|
			section_lists << [] if !section_lists[i]
			section_lists[i] << section
		end
	end
	section_lists
end

def create_markov(section)
	root = {}
	section.each do |s|
		node = root
		s.each do |c|
			node[c] = [0,{}] if !node[c]
			node = node[c]
			node[0] += 1
			node = node[1]
			# the chain ends when "C" (tonic) reached.
			node = root if (c[0].include? "C")
		end
	end
	root
end

# could be way more effeicent but w/e
def pick_markov_chord(markov)
	sel = []
	markov.keys.each {|k| markov[k][0].times { sel << k}}
	sel.sample
end

def chord_gen(markov, count)
	root = markov
	chords = []
	count.times do
		chord = pick_markov_chord(root)
		chords << chord
		root = root[chord][1]
		root = markov if root == {}
	end
	chords
end

# Sometimes I need to ignore something in the original data.
# I don't handle sus chords..yet
def clean (sec)
	sec2 = []
	last = nil
	sec.each do |bar|
		bar2 = []
		bar.each do |c|

			if (c == "/")
				bar2 << last
				next
			end

			next if (c == "sus")
			last = c
			bar2 << c 

		end
		sec2 << bar2
	end
	sec2
end


def make_song
	data = get_sample_data
	sections = collect_sections(data[1])
	# sections tend to be almost always 16, sometimes 8 or 24
	section_freq = sections.map{|s| s.count}
	markov = create_markov(sections[0])
	a = {}

	# Now we can compose.
	# We should actually inspect song structure, but this works for now.

	# Roll the dice
	case 1+rand(6)
	when 6
		a_section = 16
	else
		a_section = 8
	end

	case 1+rand(6)
	when 6
		b_section = 24
	when 5
		b_section = 16
	else
		b_section = 8
	end
	puts "#{a_section} #{b_section}"

	patterns = []

	# have A, B, or C pattern.
	(1+rand(3)).times do
		# These are chord change components, from "A" section or "B" section.
		comp = ["A", "B", "A1", "A2", "B1", "B2"].sample(2+rand(2))
		patterns << comp
	end


	song_struct = []
	(2+rand(3)).times do |t|
		song_struct << patterns[0] if (rand(2) == 0)
		song_struct << patterns.sample
	end

	# use normal distribution?
	tempo = 60 + rand(120)
	# now we have some idea of the song structure, and the tempo. Let's generate A, B, C sections
	a_section_chords = chord_gen(markov,a_section)
	b_section_chords = chord_gen(markov,b_section)

	json = {}
	json["name"] = (0...5).map { (65 + rand(26)).chr }.join
	json["tempo"] = tempo
	json["a_section"] = clean(a_section_chords)
	json["b_section"] = clean(b_section_chords)
	json["structure"] = song_struct
	json
end




100.times do 
	song = make_song
	File.write("generated_songs/#{song["name"]}.json",song.to_json)
end