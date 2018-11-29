
require_relative "music_common"

def gen_lead_line(leading,chord,len)
	events = []
	low = 48
	hi = 72
	mid = ((low + hi) / 2)
	leading = mid if !leading

	chord_root, chord_quality = get_intervals(chord[0])
	chord_quality.map!{|i| i + 36 + chord_root}

	# decide to go up or down from leading tone
	chord_quality.sample(2).each do |i|
		events << MIDI::NoteOn.new(2, i, 127, 0)
		events << MIDI::NoteOff.new(2, i, 127, len)
	end


	[events, chord_quality[1]]
end

# Figure out song structure from JSON (1, 1prime, 2, 1solo, 2, 1, 1prime)
# Come up with melodies for applicable tracks by using rhythms from file.
# Then fit melodies to words.
def add_lead_track(json,seq)
	puts "lead"
	# Create a track to hold the notes. Add it to the sequence.
	track = MIDI::Track.new(seq)
	seq.tracks << track

	# Give the track a name and an instrument name (optional).
	track.name = 'Lead'
	track.instrument = MIDI::GM_PATCH_NAMES[65]

	# Add a volume controller event (optional).
	track.events << MIDI::Controller.new(2,MIDI::CC_VOLUME, 127)


	track.events << MIDI::ProgramChange.new(2, 65, 0)
	qnl = seq.note_to_delta('quarter')

	chords_flat = []
	json["song_data"].each do |section|
		section.each do |bar|
			chords_flat << bar
		end
	end

	walk = gen_lead_line(nil,chords_flat[0],2*qnl)
	track.events += walk[0]
	walk_lead = walk[1]
	chords_flat.shift

	chords_flat.each_with_index do |c,i|
		walk = gen_lead_line(walk_lead,c,2*qnl)
		track.events += walk[0]
		walk_lead = walk[1]
	end
	# Assumes one chord per bar!
end