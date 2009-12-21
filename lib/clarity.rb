require 'clarity/util/struct_file'

require 'clarity/base'
require 'clarity/metric'
require 'clarity/metric_report'
require 'clarity/ab_test'
require 'clarity/table_metric'
require 'clarity/table_metric_report'

require 'clarity/rails'

Clarity::Base.load!

# Include in controller, add view helper methods.
ActionController::Base.class_eval do
  include Clarity::ControllerMethods
  helper Clarity::ControllerMethods
end

ActiveRecord::Base.send :extend, Clarity::ActiveRecordMethods 

# required for table metric
class Time
	def beginning_of_hour
	  self - min.minutes - sec.seconds
	end
end
