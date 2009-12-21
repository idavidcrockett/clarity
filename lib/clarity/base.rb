module Clarity
	class Base
		class << self
			def actor_id
				@actor_id
			end
			
			def set_actor_id(id)
				@actor_id = id
			end
			
			def metrics
				@metrics
			end
			
			def ab_tests
				@ab_tests
			end
			
			def track!(keyname)
				keyname = keyname.to_sym
				if @metrics[keyname].present?
					@metrics[keyname].track!
					return true
				end
				log_info("!! metric #{keyname} does not exist")
				return false
			end
			
			def load!
				@metrics = { }
				@ab_tests = { }
				
				config = Clarity::StructFile.parse_dir("#{RAILS_ROOT}/expirements")
				return if config.blank?
				return if config['metric'].blank?
				config.metric.each do |id, params|
					metric_id = id.to_sym
					options = params.to_hash
					@metrics[metric_id] = Clarity::Metric.new(metric_id, options)
				end
				
				return if config['ab_test'].blank?
				config.ab_test.each do |id, params|
					ab_test_id = id.to_sym
					options = params.to_hash
					@ab_tests[ab_test_id] = Clarity::AbTest.new(ab_test_id, options)
				end
			end
			
			def log_info(msg)
				RAILS_DEFAULT_LOGGER.info "ClarityMetric: #{msg}"
			end
		end
		
	end
end