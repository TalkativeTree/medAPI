class Result < ActiveRecord::Base
  belongs_to :source
  has_many :rankings
  has_many :searches, through: :rankings
end
