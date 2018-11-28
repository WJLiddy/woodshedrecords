require 'midilib/io/seqreader'
require 'midilib/io/seqwriter'
require 'midilib'
require 'json'

def invert(intervals, inv)
	if inv > 0
		inv.times do |e|
			val = intervals.shift
			val += 12
			intervals.insert(-1,val)
		end
	else
		inv.abs.times do |e|
			val = intervals.pop
			val -= 12
			intervals.insert(0,val)
		end
	end
	intervals
end

def root_to_mid(note)
	{"A" => 57, "B" => 59, "C" => 60, "D" => 62, "E" => 64, "F" =>65, "G" => 67}[note]
end

def quality_to_mid_offset(q)
	case q
		when "" 
			return [0,4,7]
		when "m" 
			return [0,3,7]
		when "7"  
			return [0,4,7,10]
		when "m7" 
			return [0,3,7,10]
	end
end

def gen_drum_event(chord,len)

	events = []
	accidental = 0
	if(chord.include?("b"))
		chord.gsub!("b","")
		accidental = -1
	end

	chord_root = root_to_mid(chord[0]) + accidental - 24
	chord_quality = invert(quality_to_mid_offset(chord[1..-1]),-3 + rand(6))

	chord_quality.each do |i|
		events << MIDI::NoteOn.new(10, chord_root + i, 127, 0)
	end

	chord_quality.each_with_index do |e,i|
		events << MIDI::NoteOff.new(10, chord_root + e, 127, i == 0 ? len : 0)
	end
	events
end

def gen_chord_event(chord,len)

	events = []
	accidental = 0
	if(chord.include?("b"))
		chord.gsub!("b","")
		accidental = -1
	end

	chord_root = root_to_mid(chord[0]) + accidental
	chord_quality = invert(quality_to_mid_offset(chord[1..-1]),-3 + rand(6))

	chord_quality.each do |i|
		events << MIDI::NoteOn.new(0, chord_root + i, 127, 0)
	end

	chord_quality.each_with_index do |e,i|
		events << MIDI::NoteOff.new(0, chord_root + e, 127, i == 0 ? len : 0)
	end
	events
end

def gen_bass_walk(leading,chord,next_chord,len)

	# won't play multiple chords yet
	chord = chord[0]
	events = []
	accidental = 0
	if(chord.include?("b"))
		chord.gsub!("b","")
		accidental = -1
	end

	chord_root = root_to_mid(chord[0]) + accidental
	chord_quality = invert(quality_to_mid_offset(chord[1..-1]),-3 + rand(6)).map{|i| i -= 24}

	(chord_quality << chord_quality[0] + 12) if chord_quality.count < 4 

	chord_quality.each do |i|
		events << MIDI::NoteOn.new(1, chord_root + i, 127, 0)
		events << MIDI::NoteOff.new(1, chord_root + i, 127, len)
	end

	[events,nil]
end

def add_piano_track(json,seq)
	# Create a track to hold the notes. Add it to the sequence.
	track = MIDI::Track.new(seq)
	seq.tracks << track

	# Give the track a name and an instrument name (optional).
	track.name = 'Piano'
	track.instrument = MIDI::GM_PATCH_NAMES[0]

	# Add a volume controller event (optional).
	track.events << MIDI::Controller.new(0, MIDI::CC_VOLUME, 127)

	# Add events to the track: a major scale. Arguments for note on and note off
	# constructors are channel, note, velocity, and delta_time. Channel numbers
	# start at zero. We use the new Sequence#note_to_delta method to get the
	# delta time length of a single quarter note.
	track.events << MIDI::ProgramChange.new(0, 1, 0)
	qnl = seq.note_to_delta('quarter')
	json["song_data"].each do |section|
		section.each do |bar|
			bar.each do |chord|
				track.events += gen_chord_event(chord,4*qnl)
			end
		end
	end
end

def add_bass_track(json,seq)
	# Create a track to hold the notes. Add it to the sequence.
	track = MIDI::Track.new(seq)
	seq.tracks << track

	# Give the track a name and an instrument name (optional).
	track.name = 'Bass'
	track.instrument = MIDI::GM_PATCH_NAMES[36]

	# Add a volume controller event (optional).
	track.events << MIDI::Controller.new(1, MIDI::CC_VOLUME, 127)


	track.events << MIDI::ProgramChange.new(1, 33, 0)
	qnl = seq.note_to_delta('quarter')

	chords_flat = []
	json["song_data"].each do |section|
		section.each do |bar|
			chords_flat << bar
		end
	end

	walk = gen_bass_walk(nil,chords_flat[0],chords_flat[1],qnl)
	track.events += walk[0]
	walk_lead = walk[1]
	chords_flat.each_with_index do |c,i|
		walk = gen_bass_walk(nil,c,chords_flat[i+1],qnl)
		track.events += walk[0]
		walk_lead = walk[1]
	end
	# Assumes one chord per bar!
end

def add_drum_track(json,seq)
	# Create a track to hold the notes. Add it to the sequence.
	track = MIDI::Track.new(seq)
	seq.tracks << track
	fname = Dir.entries("drum_loops/").delete_if{|e| !e.include? "."}.sample

	seq2 = MIDI::Sequence.new()
	File.open("drum_loops/"+ fname, 'rb') { | file |
		seq2.read(file) { | track2, num_tracks, i |
			next if !track2
			16.times do |n|
				track2.each do |e|
					track.events << e
				end
			end
		}
	}
end



def create_song(chart_json)
	# set up midi file.
	seq = MIDI::Sequence.new()

	# Create a first track for the sequence. This holds tempo events and stuff
	# like that.
	track = MIDI::Track.new(seq)
	seq.tracks << track
	track.events << MIDI::Tempo.new(MIDI::Tempo.bpm_to_mpq(120))
	track.events << MIDI::MetaEvent.new(MIDI::META_SEQ_NAME, 'Sequence Name')

	add_piano_track(chart_json,seq)
	add_bass_track(chart_json,seq)
	add_drum_track(chart_json,seq)
	# Calling recalc_times is not necessary, because that only sets the events'
	# start times, which are not written out to the MIDI file. The delta times are
	# what get written out.

	File.open('from_scratch.mid', 'wb') { |file| seq.write(file) }
end

create_song(JSON::parse(File.read('charts_json\a1.json')))