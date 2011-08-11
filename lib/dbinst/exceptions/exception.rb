module DBInst

  class MigrationDirectoryNotExist < Exception; end
  class MigrationFilenameInvalid   < Exception; end

  class EnvironmentNotExist        < Exception; end

  class ConfigFileNotExist         < Exception; end
  class ConfigAmbiguousEnvironment < Exception; end

  class NoEnvironmentSelected      < Exception; end

end
