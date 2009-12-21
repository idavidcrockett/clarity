class ClarityTableMetricsTableGenerator < Rails::Generator::Base
	def manifest
		record do |m|
			migration_file_name = "create_clarity_table_metrics"
			if Dir.glob(File.join(RAILS_ROOT,"db","migrate","[0-9]*_*.rb")).grep(/[0-9]+_create_clarity_table_metrics.rb$/).blank?
        m.migration_template "create_clarity_table_metrics.rb", "db/migrate", :migration_file_name=>migration_file_name
      end
		end
	end
end