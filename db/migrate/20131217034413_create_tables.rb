class CreateTables < ActiveRecord::Migration
  def change
    create_table :search_engines do |t|
      t.string :name
      t.string :base_url

      t.timestamps
    end

    create_table :terms do |t|
      t.string :name
      t.integer :topic_id
      t.timestamps
    end

    create_table :searches do |t|
      t.string  :tokens, array: true, default: []

      t.timestamps
    end

    create_table :rankings do |t|
      t.belongs_to :search
      t.belongs_to :result
      t.string    :position

      t.timestamps
    end

    create_table :results do |t|
      t.belongs_to :source
      t.string :url
      t.string :title
      t.text :summary
      t.text :snippet

      t.timestamps
    end

    create_table :sources do |t|
      t.string :title

      t.timestamps
    end

    # create_table :search_engines_searches do |t|
    #   t.belongs_to :search_engine
    #   t.belongs_to :search
    # end

    create_join_table :searches, :terms
    create_join_table :search_engines, :terms
  end
end
