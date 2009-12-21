class ClarityMetricGenerator < Rails::Generator::NamedBase
	def manifest
		record do |m|
			m.directory "expirements"
			m.template "metric.rb", "expirements/#{file_name}.rb"
		end
	end
end