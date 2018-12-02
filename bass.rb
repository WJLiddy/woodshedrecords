
require_relative "music_common"

# Simple walking on C.Ts.

# will only play first chord in measure.
def gen_bass_walk(leading,chord,next_chord,len)

	low = 28
	hi = 52
	mid = ((low + hi) / 2)

	walk_up = (leading < mid) if leading
	events = []
	chord_root, chord_quality = get_intervals(chord[0])
	chord_quality.map!{|i| i += 12}


	chord_quality.map!{|i| i + chord_root}

	if(leading && walk_up)
		# invert up 52.
		chord_quality = invert(chord_quality, 100)
				# overshoots.
		chord_quality = invert(chord_quality,-1) while (chord_quality[0] > leading)
		invert(chord_quality,1)
		(chord_quality << (chord_quality[0] + 12)) if (chord_quality.count < 4)
	end
	if(leading && !walk_up)
		chord_quality = invert(chord_quality, -100)
		# overshoots.
		chord_quality = invert(chord_quality,1) while (chord_quality[-1] < leading)
		invert(chord_quality,-1)
		chord_quality.reverse!
		(chord_quality << (chord_quality[0] - 12)) if (chord_quality.count < 4)
	end

	#if no leading, we're walking up.
	(chord_quality << (chord_quality[0] + 12)) if (chord_quality.count < 4)

	# decide to go up or down from leading tone
	chord_quality.each do |i|
		events << MIDI::NoteOn.new(1, i, 127, 0)
		events << MIDI::NoteOff.new(1, i, 127, len)
	end


	[events, chord_quality[3]]
end

def walk_sec(chords_flat,qnl,track)
	walk = gen_bass_walk(nil,chords_flat[0],chords_flat[1],qnl)
	track.events += walk[0]
	walk_lead = walk[1]
	chords_flat.shift

	chords_flat.each_with_index do |c,i|
		walk = gen_bass_walk(walk_lead,c,chords_flat[i+1],qnl)
		track.events += walk[0]
		walk_lead = walk[1]
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

	json["structure"].flatten.each do |s|

		if s.include? "A"
			chords_flat = []
			json["a_section"].each do |bar|
				chords_flat << bar
			end
			walk_sec(chords_flat,qnl,track)
		else
			chords_flat = []
			json["b_section"].each do |bar|
				chords_flat << bar
			end
			walk_sec(chords_flat,qnl,track)
		end
	end
	
	# Assumes one chord per bar!
end