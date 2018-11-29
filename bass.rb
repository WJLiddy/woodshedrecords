
require_relative "music_common"

def gen_bass_walk(leading,chord,next_chord,len)

	events = []
	chord_root, chord_quality = get_intervals(chord)
	chord_quality = invert(chord_quality,-3 + rand(6)).map{|i| i += 24}

	(chord_quality << chord_quality[0] + 12) if chord_quality.count < 4 

	chord_quality.each do |i|
		events << MIDI::NoteOn.new(1, chord_root + i, 127, 0)
		events << MIDI::NoteOff.new(1, chord_root + i, 127, len)
	end

	[events,nil]
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