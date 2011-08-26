module DBGeni

  class MigrationDirectoryNotExist < Exception; end
  class MigrationFilenameInvalid   < Exception; end
  class MigrationAlreadyApplied    < Exception; end
  class MigrationNotApplied        < Exception; end
  class MigrationApplyFailed       < Exception; end
  class MigrationContainsErrors    < Exception; end

  class EnvironmentNotExist        < Exception; end

  class ConfigFileNotExist         < Exception; end
  class ConfigAmbiguousEnvironment < Exception; end

  class NoEnvironmentSelected      < Exception; end

  # If an attempt is made to load an initializer that doesn't exist
  class NoInitializerForDBType      < Exception; end
  class NoConnectorForDBType        < Exception; end
  # If the initializer is not corretly defined, this will be raise.
  class InvalidInitializerForDBType < Exception; end
  class DatabaseAlreadyInitialized  < Exception; end
  class NoOutstandingMigrations     < Exception; end


end
