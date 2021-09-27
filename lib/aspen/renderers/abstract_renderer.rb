class AbstractRenderer

  attr_reader :statements

  def initialize(statements)
    @statements = statements
  end

  def render
    raise NotImplementedError, "Find me in #{__FILE__}"
  end

  def nodes
    raise NotImplementedError, "Find me in #{__FILE__}"
  end

  def relationships
    raise NotImplementedError, "Find me in #{__FILE__}"
  end

end
