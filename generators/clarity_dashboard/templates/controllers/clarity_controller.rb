class ClarityController < ApplicationController
	layout 'clarity'
	
	def users
		@table = Clarity::TableMetricReport.new(:users, :start_at => params[:start_at], :group_limit => 4, :interval => params[:interval])
		render :action => 'table_metric_report'
	end
	
	def ab_tests
		@ab_tests = Clarity::Base.ab_tests
	end
	
	def metrics
		@reports = [ ]
		@reports << Clarity::MetricReport.new(
			'ClickThing', 
			:metrics => [ :qm_cross_promo, :play_button, :play_toggle, :stream_referral ],
			:timeframe => (7.days.ago..Time.zone.now) 
		)
	end
end