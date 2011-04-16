
class Updates

  def initialize(settings)
    diff_files = []
    if (settings.properties.repositories)
      settings.properties.repositories.each do |repo|
        source_dir = repo.path
        accepted_dir = settings.accepted_dir(repo.name, repo.path)
      end
    end
    
  end

end
