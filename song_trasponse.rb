
require 'json'

def transpose_json(js)
	raise "didn't transpose (not in C)" if js["key"] != "C"
	js.to_json
end

fail = 0
ok = 0
Dir.entries("charts_json/").each do |file|
	next if file == "." || file == ".."

	begin
		trans = transpose_json(JSON::parse(File.read("charts_json/#{file}")))
	rescue StandardError => e  
		puts "for #{file}"
		puts e
		fail += 1
		next
	end
	ok += 1
	File.write("transposed_charts_json/#{file.split(".")[0]}.json",trans)
end
puts "ok #{ok} fail #{fail}"