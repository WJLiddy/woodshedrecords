def get_intervals(chord)
		# won't play multiple chords yet
	chord = chord[0]
	events = []
	accidental = 0
	if(chord.include?("b"))
		chord.gsub!("b","")
		accidental = -1
	end

	chord_root = root_to_mid(chord[0]) + accidental
	chord_quality = quality_to_mid_offset(chord[1..-1])
	return [chord_root,chord_quality]
end
#	chord_quality = invert(quality_to_mid_offset(chord[1..-1]),-3 + rand(6)).map{|i| i += 12*oct}
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
	{"A" => 9, "B" => 11, "C" => 12, "D" => 14, "E" => 16, "F" =>17, "G" => 19}[note]
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
