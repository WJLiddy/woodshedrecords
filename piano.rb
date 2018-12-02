
require_relative "music_common"

def gen_chord_event(chord,len)
	events = []

	chord_root, chord_quality = get_intervals(chord)

	invert(chord_quality,1) while ((chord_quality.sum / chord_quality.count) < 45)

	chord_quality.each do |i|
		events << MIDI::NoteOn.new(0, chord_root + i, 127, 0)
	end

	chord_quality.each_with_index do |e,i|
		events << MIDI::NoteOff.new(0, chord_root + e, 127, i == 0 ? len : 0)
	end

	events
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


	json["structure"].flatten.each do |s|

		if s.include? "A"

			json["a_section"].each do |bar|
				bar.each do |chord|
					track.events += gen_chord_event(chord,(4/bar.length)*qnl)
				end
			end

		else

			json["b_section"].each do |bar|
				bar.each do |chord|
					track.events += gen_chord_event(chord,(4/bar.length)*qnl)
				end
			end

		end
	end
end
