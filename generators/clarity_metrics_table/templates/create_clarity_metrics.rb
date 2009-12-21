class CreateClarityMetrics < ActiveRecord::Migration
	def self.up
		create_table :clarity_metrics do |t|
			t.string :keyname, :null => false
			t.date :date, :null => false
			t.integer :track_count, :default => 0
		end
		add_index :clarity_metrics, :keyname
		add_index :clarity_metrics, :date
	end
	def self.down                
		remove_index :clarity_metrics, :keyname
		remove_index :clarity_metrics, :date
		drop_table :clarity_metrics
	end
end