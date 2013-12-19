class SearchEngine < ActiveRecord::Base
  has_and_belongs_to_many :terms
  has_many :searches, through: :terms
end

# class Term < ActiveRecord::Base
#   has_and_belongs_to_many :searches
#   has_and_belongs_to_many :searche_engines
# end

# class Result < ActiveRecord::Base
#   belongs_to :source
#   has_many :rankings
#   has_many :searches, through: :rankings
# end

# class Source < ActiveRecord::Base
#   has_many :results
# end

# class Ranking < ActiveRecord::Base
#   belongs_to :search
#   belongs_to :result
# end

# class Search < ActiveRecord::Base
#   has_many :rankings
#   has_many :results, through: :rankings
#   has_and_belongs_to_many :terms
#   has_many :search_engines, through :terms
# end














