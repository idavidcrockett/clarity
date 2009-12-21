module Clarity
	class MetricReport
	
		attr :name
		attr_reader :rows
		attr_reader :keynames
	
		def initialize(name, params={})
			@name = name 
		
			timeframe = params[:timeframe]
			raise "timeframe required" if timeframe.blank?
		
			keynames = params[:metrics]
			raise "metrics required" if keynames.blank?  
			keynames.collect!{ |k| k.to_s } if keynames.is_a?(Array)
			keynames=keynames.to_s if keynames.is_a?(Symbol)
			keynames=keynames.split(",") if keynames.is_a?(String)
			@keynames = keynames
			
			records = Clarity::MetricRecord.find(
				:all, 
				:conditions => {
					:keyname => @keynames,
					:date => timeframe
				},
				:order => 'date DESC' 
			)
		
			@rows = [ ]
			records.map{ |r| r.date }.uniq.each do |date|
				counts = @keynames.collect do |keyname|
					record = records.find{ |r| (r.keyname.to_s==keyname.to_s and r.date==date) }
					if record.present?
						record.track_count.to_i
					else
						-1
					end
				end
				@rows << [ date, counts ]
			end
		
		end
	
	end
end