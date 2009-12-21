class ClarityTablesGenerator < Rails::Generator::Base
	def manifest
		record do |m|
			migration_file_name = "create_clarity_tables"
			if Dir.glob(File.join(RAILS_ROOT,"db","migrate","[0-9]*_*.rb")).grep(/[0-9]+_create_clarity_tables.rb$/).blank?
        m.migration_template "create_clarity_tables.rb", "db/migrate", :migration_file_name=>migration_file_name
      end
		end
	end
end