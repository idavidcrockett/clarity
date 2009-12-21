module Clarity
	
	# == Schema Information
	#
	# Table name: table_metrics
	#
	#  record     :string			not null
	#  label      :string			not null
	#  total			:integer		default 0
	#  logged_at	:datetime		not null
	#  created_at :datetime
	#  updated_at :datetime
	#
	class TableMetric < ActiveRecord::Base
		
		set_table_name 'table_metrics'
		
		validates_uniqueness_of :logged_at, :scope => [ :record, :label ]
		validates_presence_of :record, :label, :logged_at

		class Updater
			def initialize(record, group=nil)
				# record should be an active record model
				# group is optional, group records by attribute, e.g. language
				@record=record; @group=group
			end
			def execute!
				records = find_new_metrics
				records.each do |r|	
					# save each record as a metric
					logged_at = r.created_at.beginning_of_hour
					total = r.total.to_i
					label = labelize(r)
					log "- #{logged_at} - #{total} - #{label}"

					metric = TableMetric.new( 
					  :logged_at => logged_at,
						:total 		 => total,
						:label 		 => label,
						:record 	 => @record.to_s )

					unless metric.save
						log "failed to save! #{metric.errors.full_messages}"
						# search for duplicate
						duplicate_record = TableMetric.find(:first, 
							:conditions => { 
								:record => metric.record,
								:label =>	metric.label,
								:logged_at => metric.logged_at } )

						unless duplicate_record.blank?
							log "duplicate found! updating total"
							duplicate_record.total = metric.total		
							unless duplicate_record.save
								log "failed to update total! #{duplicate_record.errors.full_messages}"
							end
						else
							log "ignoring failure"
						end
					end
				end

				def destroy
					TableMetric.destroy_all :record   => @record.to_s, 
												 		 			:interval => @interval.to_s
				end
			end

			private

				def find_new_metrics
					# calculates new metrics for the record
					# sample output [ User: total ]
					start_time = latest_metric_logged_at
					stop_time = Time.zone.now
					return [ ] if start_time >= stop_time  
					record_class.find( :all,
						:select => selects, 
						:conditions => { 
							:created_at => start_time .. stop_time },
						:group => "scope",
						:order => "created_at DESC" )
				end

				def record_class
					# converts :user to User
					@record_class ||= @record.to_s.classify.constantize
				end

				def latest_metric_logged_at
					# finds when the most recent metric was logged at
					metric = TableMetric.find( :first, 
																:conditions => { 
																	:record => @record.to_s },
																:order => 'logged_at desc' )
					if metric.blank?
						return Time.at(0)
					else
						return metric.logged_at.in_time_zone
					end
				end

				def selects
					[ "CAST(count(*) AS SIGNED) as total", 
			      scope, @group, "created_at" ].compact.join(",")
				end

				def scope
					time_group = "concat(DATE_FORMAT(created_at, '%Y-%d-%m'), TIME_FORMAT(created_at, '%H'))"
					@group.nil? ? "#{time_group} as scope" : "concat(#{time_group}, #{@group}) as scope"
				end

				def labelize(record)
					@group.nil? ? "total_count" : record.attributes[@group.to_s]
				end

				def log(str)
					# RAILS_DEFAULT_LOGGER.info("TableMetric::Updater(#{@record},#{@interval},#{@group}): #{str}")
					puts("TableMetric::Updater(#{@record},#{@group}): #{str}")
				end
		end					

		class GroupedChart
			attr_reader :record
			attr_reader :end_at
			attr_reader :rows

			def self.demo
				c = new(:users, :end_at => Time.now)
				c.print_to_console
			end

			# :users, :end_at => Time.now
			def initialize(*args)
				@record = args.first.to_s
				params = args.last
				@end_at = params[:end_at]
				start_at = @end_at - 36.hours

				# create the rows
				@rows = [ ]
				records = TableMetric.find(:all, 
					:conditions => { 
						:record 	 => @record, 
						:logged_at => start_at .. @end_at })
				ordered_times = records.map(&:logged_at).uniq.sort.reverse
				ordered_times.each do |time|
					data = records.find_all { |r| r.logged_at==time }.collect { |r| [r.label, r.total] }
					# calculate total
					data << [ 'total', data.collect { |i| i.last.to_i }.sum ] 
					data = data.sort { |a,b| b.last <=> a.last }
					@rows << Row.new(time,data)
				end
			end

			class Row
				attr_reader :time
				attr_reader :data
				def initialize(time,data)
					@time=time
					@data=data
				end
			end

			def print_to_console
				puts "GroupedChart(table:#{@record} ending_at:#{@end_at})"
				@rows.each do |row|
					puts "#{row.time}"
					row.data.each do |datum|
						label,total = datum
						puts "\t#{label} #{total}"
					end
				end
				true
			end

		end

		class << self
			 
			def track!(tablename, opts={})
				# exmaple usuage:
				# - track! :users, :group => :language
				# - track! :answers
				# valid options:
				# + :group
				@track ||= { }
				@track[tablename.to_sym] = opts
			end
			
			def run_update(*args)
				# update metrics for tables being tracked
				# args :users, :answers
				args.each do |table|
					Updater.new(table.to_s, @track[table.to_sym][:group]).execute!
				end
				if args.blank?
					@track.each do |table, params|
						Updater.new(table.to_s, params[:group]).execute!
					end
				end
			end
			def log(str)
				RAILS_DEFAULT_LOGGER.info("TableMetric: #{str}")
			end
		end

		def log(str)
			RAILS_DEFAULT_LOGGER.info("TableMetric(#{self.id}): #{str}")
		end
	end
	
	
end