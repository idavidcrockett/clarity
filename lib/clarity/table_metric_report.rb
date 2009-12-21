module Clarity
	class TableMetricReport

		attr_reader :maximum
		attr_reader :rows

		attr_reader :interval
		attr_reader :timezone

		def initialize(tablename, params={})
			@timezone = (params[:timezone] or 'Pacific Time (US & Canada)')
			# convert start at to the correct time zone
			# start_at "2009-12-03" in pacific to utc
			@offset = Time.zone.now.in_time_zone(@timezone).utc_offset
			@start_at = ( params[:start_at] or Time.zone.now.in_time_zone(@timezone).to_date.to_s ).to_datetime.in_time_zone.beginning_of_day - @offset
			@interval = ( params[:interval] or :hourly ).to_sym
	    case @interval
			when :hourly
				# start at the beginning of the day
				# end at the end of the day
				@end_at = (@start_at+23.hours+59.minutes+59.seconds)
				@display_date = @start_at
			when :daily
				# start 14 days in the past
				# end at the current day
				@end_at = @start_at+23.hours+59.minutes+59.seconds
				@start_at = @start_at - 14.days
				@display_date = @end_at
			end

			@group_limit = (params[:group_limit] or 1)
			@tablename = tablename.to_s

			# find the metrics
			metrics = Clarity::TableMetric.find(:all, 
				:conditions => {
					:record => @tablename, 
					:logged_at => @start_at .. @end_at }, 
				:order => 'logged_at DESC')

			# if daily compress the metrics
			if @interval==:daily
				daily_totals = metrics.inject({}) do |table, metric|
					# hash: date,label = total
					daykey = metric.logged_at.in_time_zone(@timezone).beginning_of_day
					table[daykey] ||= { }
					table[daykey][metric.label] ||= 0
					table[daykey][metric.label] += metric.total.to_i
					table
				end
				metrics = [ ]
				daily_totals.each do |day, groups|
					groups.each do |label, total|
						metrics << Clarity::TableMetric.new(:logged_at => day, :label => label, :total => total)
					end
				end
			end

			# order the groups
			group_counts = metrics.inject({}) do |table, metric|
				table[metric.label] ||= 0 
			  table[metric.label] += metric.total.to_i
				table
			end
			group_counts = group_counts.to_a.sort {|a,b| b.last<=>a.last }
	    @groups = group_counts.to_a.sort {|a,b| b.last<=>a.last }.collect{ |i| i.first }

			# find the maximum
			@maximum = metrics.inject({}) do |table, metric|
				table[metric.logged_at] ||= 0
				table[metric.logged_at] += metric.total.to_i
				table
			end.values.sort.last

			# find the rows
			@rows = metrics.map(&:logged_at).uniq.sort.reverse.inject([]) do |set, time|
				set << Row.new(self,metrics.find_all { |r| r.logged_at==time })
			end
		end

		def groups
			@groups[0..@group_limit]
		end

		def date_label
			@display_date.in_time_zone(@timezone).strftime("%a. %m-%d-%y")
		end

		def date_picker_value
			@display_date.in_time_zone(@timezone).strftime("%d/%m/%Y")
		end

		def range(high_or_low)
			@range ||= { }
			# date format specific to date_picker javascript
			# e.g. "19700313"
			order = high_or_low.to_sym == :high ? "DESC" : "ASC"
			@range[high_or_low.to_sym] ||= Clarity::TableMetric.find(
				:first, 
				:conditions => { :record => @tablename },
				:order => "logged_at #{order}" 
			).logged_at.in_time_zone(@timezone).strftime("%Y%m%d")
		end

		def log(msg)
			RAILS_DEFAULT_LOGGER.debug msg
		end

		class Row

			attr_reader :time
			attr_reader :total

			def initialize(chart, metrics)
				@chart = chart
				@logged_at = metrics.first.logged_at
				# find total
				@total = metrics.map(&:total).sum
				@group_hash = metrics.inject({}) do |set, record|
					set[record.label] = Col.new(@chart, self, record.label, record.total)
					set
				end
			end
			def groups
				@groups ||= @chart.groups.collect do |name|
					@group_hash[name] or Col.new(@chart,self,name,0)
				end
			end
			def start_at
				@logged_at.in_time_zone(@chart.timezone).to_date.to_s
			end
			def time_label
				t = @logged_at.in_time_zone(@chart.timezone)
				case @chart.interval
				when :daily
					# Thu. 12-17-09
					t.strftime("%a. %m-%d-%y")
				when :hourly
					# 9AM
					t.strftime("%I%p")
				end
			end

			class Col
				attr_reader :label
				attr_reader :total
				def initialize(chart, row, label, total)
					@chart = chart
					@row = row
					@label = label
					@total = total
				end
				def total_percent
					@total_percent ||= ((self.total.to_f/@chart.maximum.to_f)*100.0).to_i
				end
				def local_percent
					@local_percent ||= ((self.total.to_f/@row.total.to_f)*100.0).to_i
				end
			end

		end

	end
end