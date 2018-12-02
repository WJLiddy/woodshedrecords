require 'midilib/io/seqreader'
require 'midilib/io/seqwriter'
require 'midilib'
require 'json'

require_relative "bass"
require_relative "piano"
require_relative "lead"


def add_drum_track(json,seq)
	# Create a track to hold the notes. Add it to the sequence.
	track = MIDI::Track.new(seq)
	seq.tracks << track
	fname = Dir.entries("drum_loops/").delete_if{|e| e == "." || e == ".."}.sample

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
	add_lead_track(chart_json,seq)
	add_drum_track(chart_json,seq)
	# Calling recalc_times is not necessary, because that only sets the events'
	# start times, which are not written out to the MIDI file. The delta times are
	# what get written out.

	File.open("realized_songs/#{chart_json["name"]}.mid", 'wb') { |file| seq.write(file) }
end

Dir.entries("generated_songs/").each do |e|
	next if e == "." || e == ".."
	next if File.exists?("realized_songs/#{e}")
	create_song(JSON::parse(File.read("generated_songs/#{e}")))
end