class Search < ActiveRecord::Base
  has_many :rankings
  has_many :results, through: :rankings
  has_and_belongs_to_many :terms
  has_many :search_engines, through: :terms

  def self.convert(term)
    SearchTermConverter.postgres_array(term)
  end

end

class SearchSet
  def self.all(term)
    tokens = SearchTermConverter.tokenize(term)
    # tokens = PostgressArrayConverter.postgres_array(search_term)
    tokens.map{|token| Search.where("#{token} = ANY (tokens)")}
  end
end

class SearchTermConverter
  UNWANTED = ['',' ', ',', ';']
  UNWANTED_REGEX = /(,| |;)/

  def self.postgres_array(term)
    tokens = self.tokenize(term)
    "{" + tokens.join(",") + '}'
  end

  def self.tokenize(term)
    t = if term.match(UNWANTED_REGEX)
          split(term.downcase)
        else
          [term]
        end

    t.sort
  end

  def self.split(term)
    term.split(UNWANTED_REGEX).reject!{|s| UNWANTED.include?(s)}
  end
end