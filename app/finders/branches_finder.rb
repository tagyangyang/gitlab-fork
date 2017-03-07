class BranchesFinder
  def initialize(repository, params)
    @repository = repository
    @params = params
  end

  def execute
    rugged_branches = @repository.rugged_branches_sorted_by(sort)
    rugged_branches = by_name(rugged_branches)

    rugged_branches.map { |ref| Gitlab::Git::Branch.new(@repository.raw_repository, ref.name, ref.target) rescue nil }.compact
  end

  def sort
    @params[:sort].presence || SortingHelper.sort_value_name
  end

  private

  attr_reader :repository, :params

  def search
    @params[:search].presence
  end

  def by_name(branches)
    return branches unless search
    branches.select { |ref| ref.name.include?(search) }
  end
end
