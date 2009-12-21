module Clarity
	
	module ActiveRecordMethods
		def track_table!(opts = {})
			Clarity::TableMetric.track!(table_name.to_sym, opts)
		end
	end
	
	module ControllerMethods
		
		def set_clarity_actor(actor_id)
			Clarity::Base.set_actor_id(actor_id)
		end
		
		def track!(keyname)
			Clarity::Base.track!(keyname.to_sym)
		end
		
		def track_params!
			keyname = params.delete(Clarity::Metric::URL_KEY)
			if keyname.present?
				track!(keyname)
			end
			return true
		end
		
		def ab_test(keyname)
      ab_test = Clarity::Base.ab_tests[keyname.to_sym]
			if ab_test.present?
				return ab_test.choose
			else
				raise "invalid test"
			end
    end
		
	end
	
end