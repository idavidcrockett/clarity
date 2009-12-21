module Clarity

	class Metric
		
		URL_KEY = :clarity
		
		attr_reader :ab_tests
		attr_reader :keyname
		
		def initialize(keyname, params={})
			@keyname = keyname
			@date = Time.now.in_time_zone("Pacific Time (US & Canada)").to_date
			@description = params[:description]
			@ab_tests = [ ]
		end
		
		def add_ab_test(ab_test)
			@ab_tests << ab_test
		end
		
		def track!
			log("track!")
			count = cache.increment(cache_key)
			if count.nil?
				log("initialzing cached counter to #{cache_key}")
				# inialize the cache counter
				cache.write(cache_key, 1) 
				count = 0
			end
			if count > 10
				# reset the cache counter to 0
				cache.decrement(cache_key, count)
				# update the record
				update_record_counter(count)
			end
			# track ab tests
			@ab_tests.each { |ab_test| ab_test.choosen_alternative.convert!(self) }
			return count
		end
		
		def cache_key
			"ClarityMetric::#{@date.to_s}::#{@keyname.to_s}"
		end
		
		def update_record_counter(by)
			log("updating record counter by #{by}")
			record_class.increment_count(self.record_id, by)
			by
		end
		
		def cache
			Rails.cache
		end
		
		def record_class
			Clarity::MetricRecord
		end
		
		def record_id
			if @record_id.present?
				return @record_id
			end
			
			record_cache_key = "#{cache_key}::record_id"
			r_id = cache.read(record_cache_key)
			if r_id.blank?
				log("record_id not found in cache #{record_cache_key}")
				@record = record_class.find_or_create_by_keyname_and_date(@keyname.to_s, @date)
				r_id = @record.id
				log("saving record_id: #{r_id} as #{record_cache_key}")
				cache.write(record_cache_key, r_id)
			end
			@record_id = r_id
			@record_id
		end
		
		def log(msg)
			RAILS_DEFAULT_LOGGER.info "ClarityMetric: #{msg}"
		end
    
		def destroy
			cache.delete(cache_key)
			record_class.find(self.record_id).destroy
		end
    
		def human_name
			"#{@keyname}".humanize.titlecase
		end

		def track_count
			record_count = record_class.find(self.record_id).track_count.to_i 
			cache_count = ( cache.increment(cache_key, 0) or 0 )
			record_count + cache_count
		end
		
		def values(begin_date,end_date)
			# returns array of values like:
			#  [ [ today, track_count ], [ yesterday, track_count ] ]
			record_class.find(
				:all, 
				:conditions => { 
					:date => (begin_date..end_date), 
					:keyname => @keyname.to_s 
				},
				:order => "date DESC"
			).collect { |i| [ i.date, i.track_count ] }
		end

	end
	
	class MetricRecord < ActiveRecord::Base
		# Schema
		#   table: clarity_metrics
		#   keyname: string
		#   date: date
		#   track_count: integer
		set_table_name 'clarity_metrics'
		
		def self.increment_count(id, by)
			self.update_counters id, :track_count => by
		end
	end
end