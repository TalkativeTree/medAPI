class Term < ActiveRecord::Base
  has_and_belongs_to_many :searches
  has_and_belongs_to_many :search_engines

  has_many :alternatives, class_name: "Term", foreign_key: "topic_id"
  belongs_to :topic, class_name: "Term", foreign_key: "topic_id"
end
