class CreateClarityTableMetrics < ActiveRecord::Migration
	def self.up
		create_table :table_metrics do |t|
      t.string :record, :null => false
      t.string :label, :null => false
      t.integer :total, :default => 0
      t.datetime :logged_at, :null => false

      t.timestamps
    end
		add_index :table_metrics, :record
		add_index :table_metrics, :label
		add_index :table_metrics, :logged_at
	end
	def self.down                
		remove_index :table_metrics, :record
		remove_index :table_metrics, :label
		remove_index :table_metrics, :logged_at
		drop_table :table_metrics
	end
end