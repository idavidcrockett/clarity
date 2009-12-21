class ClarityDashboardGenerator < Rails::Generator::Base
	def manifest
		record do |m|
			# controllers
			m.template "controllers/clarity_controller.rb", "app/controllers/clarity_controller.rb"
			
			# views
			m.directory "app/views/clarity"
			[ 'ab_tests', 'metrics', 'table_metric_report' ].each do |view_name|
				m.file "views/#{view_name}.html.erb", "app/views/clarity/#{view_name}.html.erb"
			end
			m.file "views/layout.html.erb", "app/views/layouts/clarity.html.erb"
			
			# stylesheets
			m.directory "public/stylesheets/clarity"
			[ 'clarity', 'clarity_grid', 'date_picker' ].each do |filename|
				m.file "stylesheets/#{filename}.css", "public/stylesheets/clarity/#{filename}.css"
			end
			
			# javascripts
			m.directory "public/javascripts/clarity"
			m.file "javascripts/date_picker.js", "public/javascripts/clarity/date_picker.js"
			m.directory "public/javascripts/clarity/lang"
			m.file "javascripts/lang/en.js", "public/javascripts/clarity/lang/en.js"
			
			# images
			m.directory "public/images/clarity"
			m.file "images/sprite.png", "public/images/clarity/sprite.png"
			m.directory "public/images/clarity/date_picker"
			[ 'backstripes.gif', 'bg_header.jpg', 
				'bullet1.gif', 'bullet2.gif', 
				'cal-grey.gif', 'cal.gif', 
				'gradient-e5e5e5-ffffff.gif' ].each do |filename|
				m.file "images/date_picker/#{filename}", "public/images/clarity/date_picker/#{filename}"
			end
			
		end
	end
end
