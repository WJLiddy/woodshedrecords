require 'midilib/io/seqreader'
require 'midilib/io/seqwriter'
require 'midilib'

def hashsubhash(hsh,s,e)
	sum = 0
	(s...e).each do |i|
		sum += (hsh[i] ? hsh[i].hash() : 0)
	end
	sum
end
#naive algo
def rep_measure_idxs(measures_hash, measure_length)
	bars = []
	measures_hash.keys.each do |k|
		# calculate combined hash of (k + n)
		a = hashsubhash(measures_hash,k, k + measure_length)
		#puts a
		# compare to combined hash of (k + 2n)
		b = hashsubhash(measures_hash,k + measure_length, k + (2*measure_length))
		#puts b
		if a == b
			bars << k
			(k..k+measure_length).each { |f| measures_hash.delete(f)}
		end
	end
	bars
end

def extract_drum_loop_from_track(track, measure_length, ppqn)
	# first, put a list of notes in each bar. That way, we can see if any measures repeat.
	bars = {}
	track.each do |t|
		if (t.is_a?(MIDI::NoteOn))
			qn = (t.time_from_start.to_f / ppqn.to_f)
			bar = (qn / 4).to_i
			bars[bar] = [] if !bars[bar]
			# deal with floating point approx's by * 100'ing.
			bars[bar] << (100 *(qn % 4)).to_i
		end
	end
	# now we have each bar, with notes. Look for a repetition.
	rep_measure_idxs(bars, 8)
end

# Save drum loops of various measure lengths.
def extract_drum_loop(file_name, measure_length)
	# Create a new, empty sequence.
	seq = MIDI::Sequence.new()
	# Read the contents of a MIDI file into the sequence.
	File.open(file_name, 'rb') { | file |
		# Better way to detect drum tracK? ch 10 not working.
		seq.read(file) { | track, num_tracks, i |
			next if !track
			if track.name.upcase.include? "DRUM"
				bars = extract_drum_loop_from_track(track,measure_length,seq.ppqn)
				puts bars.inspect, file_name if (bars.count > 0)
				bars.each do |b|
					s = MIDI::Sequence.new
					# Create a track to hold the notes. Add it to the sequence.
					t = MIDI::Track.new(s)
					s.tracks << t
					t.events << MIDI::Tempo.new( MIDI::Tempo.bpm_to_mpq(120))
					t.events <<  MIDI::MetaEvent.new( MIDI::META_SEQ_NAME, 'Sequence Name')
					# Give the track a name and an instrument name (optional).
					t.name = 'DRUM'
					t.instrument =  MIDI::GM_PATCH_NAMES[0]
					# Add a volume controller event (optional).
					t.events <<  MIDI::Controller.new(0,  MIDI::CC_VOLUME, 127)
					track.each do |e|
						if ((e.time_from_start > (4 * seq.ppqn * (b - 1))) && e.time_from_start < ((4 * seq.ppqn * (b + -1 + measure_length))))
							t.events << e
						end
					end
					puts t.count
					File.open("drum_loops/#{measure_length}_#{file_name.gsub("/","").gsub(".","")}_#{b}.mid", 'wb') { | f2 | s.write(f2) }
				end
			end
	    }
	}
end


Dir.entries("midis/").each do |midi_file|
	next if midi_file == "." || midi_file == ".."
	extract_drum_loop("midis/#{midi_file}",8)
end