require_relative "music_common"
require 'perlin_noise'


# next time: convert to class.
def gen_lead_note(interval,chord,len, id)
	# smarter lead line comp. CTs only right now.
	events = []
	chord_root, chord_quality, chord_scale = get_intervals(chord)
	chord_quality.map!{|i| i + 36 + chord_root}
	chord_scale.map!{|i| i + 36 + chord_root}
	i = chord_quality[interval % chord_quality.count]

=begin
	a = chord_scale.find_index{|c| ((c % 12) == (interval % 12))}
	(interval -= 1) if !a
	a = chord_scale.find_index{|c| ((c % 12) == (interval % 12))}
	(interval -= 1) if !a
	a = chord_scale.find_index{|c| ((c % 12) == (interval % 12))}
=end

	if( interval == -1)
		events << MIDI::NoteOff.new(id, 50, 127, len)
	else
		events << MIDI::NoteOn.new(id,i, 127, 0) 
		events << MIDI::NoteOff.new(id, i, 127, len)
	end

	events
end

def gen_rhythm(bars, rhythm_bias)
	rhythm = [1,1,1,1,1,1,2,2,2,2,3,3,4,4,4,4,6,8,8,12,16]
	if(rhythm_bias > 0)
		rhythm.shift(rhythm_bias.abs)
	else
		rhythm.pop(rhythm_bias.abs)
	end

	r = []
	(16* bars).times do
		r << rhythm.sample
	end
	r
end

def gen_contour(bars, noise_ratio)
	aoff = rand(100).to_f
	boff = rand(100).to_f
	ncontour = Perlin::Noise.new 1, :seed => rand(10000)
	nactive = Perlin::Noise.new 1, :seed => rand(10000)
	r = []
	(16 * bars).times do |f|
		if ((nactive[(aoff+f.to_f)/200.0]) % 0.01 > (noise_ratio * 0.01))
			r << nil
			next
		end
		r << ((ncontour[(boff + f)/100.0]  % 0.01 > 0.005) ? 1 : -1)
	end
	r
end

def chord_to_16_list(section)
	list = []
	section.each do |bar|
		bar.each do |chord|
			(16/bar.count).times {list << chord}
		end
	end
	list
end

def write_section(rhythm,contour,chord,qnl,id)
	beat_ptr = 0
	note_rng = 40
	evs = []
	while(beat_ptr < (chord.count)) do
		dur = rhythm.shift
		tcontour = contour.shift
		if ((beat_ptr + dur) >= (chord.count))
			dur = chord.count - beat_ptr
			tcontour = nil
		end
		if tcontour == nil
			evs += gen_lead_note(-1,chord[beat_ptr],(qnl * 0.25 * dur).to_i,id)
		else
			note_rng += tcontour
			evs += gen_lead_note(note_rng,chord[beat_ptr],(qnl * 0.25 * dur).to_i,id)
		end
		beat_ptr += dur
	end
	evs
end

# Figure out song structure from JSON (1, 1prime, 2, 1solo, 2, 1, 1prime)
# Come up with melodies for applicable tracks by using rhythms from file.
# Then fit melodies to words.
def add_lead_track(json,seq, id,opts)
	# Create a track to hold the notes. Add it to the sequence.
	track = MIDI::Track.new(seq)
	seq.tracks << track

	# Give the track a name and an instrument name (optional).
	track.name = 'Lead'
	track.instrument = MIDI::GM_PATCH_NAMES[opts["patch"]]

	# Add a volume controller event (optional).
	track.events << MIDI::Controller.new(id,MIDI::CC_VOLUME, 127)


	track.events << MIDI::ProgramChange.new(id, opts["patch"], 0)
	qnl = seq.note_to_delta('quarter')

	a_stuff = [gen_rhythm(json["a_section"].count,opts["rhythm_bias"]),gen_contour(json["a_section"].count,opts["noise_ratio"]), chord_to_16_list(json["a_section"]),qnl]
	b_stuff = [gen_rhythm(json["b_section"].count,opts["rhythm_bias"]),gen_contour(json["b_section"].count,opts["noise_ratio"]), chord_to_16_list(json["b_section"]),qnl]

	json["structure"].flatten.each do |s|
		if s.include? "A"
			track.events += write_section(a_stuff[0].clone,a_stuff[1].clone,a_stuff[2],a_stuff[3],id)
		else
			track.events += write_section(b_stuff[0].clone,b_stuff[1].clone,b_stuff[2],b_stuff[3],id)
		end
	end
	# Assumes one chord per bar!
end