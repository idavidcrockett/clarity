module Clarity
		
	class AbTest
		
		attr_reader :keyname
		attr_reader :alternatives
		attr_reader :metrics
		
		def initialize(keyname, params={})
			@keyname = keyname.to_sym
			
			# Initialize Metrics
			@metrics = [ ]
			if params[:metrics].blank?
				raise "you must add a metric"
			end
			@metrics = params[:metrics].to_s.split(', ')
			@metrics.collect! do |keyname|
				keyname = keyname.to_sym
				metric = Clarity::Base.metrics[keyname]
				if metric.blank?
					raise "#{keyname} is invalid"
				end
				metric.add_ab_test(self)
				metric
			end
			
			# Initialize Alternatives
			a_values = [ true, false ] # default alternative values
			if params[:alternatives].present?
				if params[:alternatives].is_a?(Array)
					a_values = params[:alternatives]
				elsif params[:alternatives].is_a?(String)
					a_values = params[:alternatives].split(",")
				else
					raise "alternatives must be a string or array"
				end
			end
			if a_values.size<2
				raise "there must be two alternatives"
			end
			@alternatives = a_values.collect{ |v| Clarity::AbTest::Alternative.new(v, self) }
		end
		
		def choose
			alt = choosen_alternative 
			log(:debug, "choosing alt #{alt.value}")
			alt.participate!
			return choosen_alternative.value
		end
				
		def choosen_alternative
			log(:debug, "choosing index from key: #{@keyname}/#{Clarity::Base.actor_id} ") 
			index = Digest::MD5.hexdigest("#{@keyname}/#{Clarity::Base.actor_id}").to_i(17) % @alternatives.size
			@alternatives[index]
		end  
		
		def log(target, msg)
			msg = "AbTest[#{@keyname}] : #{msg}"
			if target==:debug
				RAILS_DEFAULT_LOGGER.debug(msg)
			elsif target==:info
				RAILS_DEFAULT_LOGGER.info(msg)
			elsif target==:stdout
				puts msg
			end
		end
		
		def human_name
			"#{@keyname}".humanize.titlecase
		end
		
		def sorted_metrics
			@metrics.sort{ |a,b| a.keyname.to_s <=> b.keyname.to_s }
		end
		
		class Alternative
			attr_reader :value
			attr_reader :participant_metric
			attr_reader :conversion_metrics
			
			def initialize(value, ab_test)
				@ab_test=ab_test
				@value=value
				@participant_metric = Clarity::Metric.new("AbTest:#{@ab_test.keyname}:alt:#{@value}:participant", :description => '')
				@conversion_metrics = { }
				@ab_test.metrics.each do |metric|
					@conversion_metrics[metric] = Clarity::Metric.new("AbTest:#{@ab_test.keyname}:alt:#{@value}:#{metric.keyname}", :description => '')
				end
			end
			
			def participate!
				@participant_metric.track!
			end
			
			def convert!(metric)
				@conversion_metrics[metric].track!
			end
			
		end
		
	end
	
end