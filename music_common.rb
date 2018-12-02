def get_intervals(chord)
	events = []
	accidental = 0
	chord_root_str = chord[0]
	chord_root_str += chord[1] if (chord[1] == "b" || chord[1] == "#")

	chord_qual_str = chord[(chord_root_str.length)..-1]
	
	if(chord_root_str[1] == ("b"))
		chord_root_str.gsub!("b","")
		accidental = -1
	end

	if(chord_root_str[1] == ("#"))
		chord_root_str.gsub!("#","")
		accidental = 1
	end

	chord_root = root_to_mid(chord_root_str) + accidental
	chord_quality = quality_to_mid_offset(chord_qual_str)
	chord_scale = quality_to_scale(chord_qual_str)
	return [chord_root,chord_quality,chord_scale]
end
#	chord_quality = invert(quality_to_mid_offset(chord[1..-1]),-3 + rand(6)).map{|i| i += 12*oct}
def invert(intervals, inv)
	if inv > 0
		inv.times do |e|
			val = intervals.shift
			intervals.push(val + 12)
		end
	else
		inv.abs.times do |e|
			val = intervals.pop
			intervals.unshift((val - 12))
		end
	end
	intervals
end

def root_to_mid(note)
	{"A" => 9, "B" => 11, "C" => 12, "D" => 14, "E" => 16, "F" =>17, "G" => 19}[note]
end

def quality_to_scale(q)
	scale = [0,2,4,5,7,9,11,12]
	if q.include? "m"
		scale[2] -= 1
		scale[6] -= 1
	end
	if q.include? "7" 
		scale[6] -= 1 if (scale[6] == 11)
	end
	if q.include? "b5"
		scale[4] -= 1
	end
	if q.include? "dim"
		scale[2] -= 1
		scale[4] -= 1
		scale[6] -= 1
	end
	if q.include? "+"
		scale[4] += 1
	end
	return scale
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
		when "m7b5"
			return [0,3,6,10]
		when "dim"
			return [0,3,6,10]
		when "6"
			return [0,4,7,9]
		when "m6"
			return [0,3,7,9]
		when "7+"
			return [0,4,8,10]
		when "7b5"
			return [0,4,6,10]
		when "9"
			return [0,2,4,7,10]
		when "m7sus"
			return [0,3,7,10]
	end
end
