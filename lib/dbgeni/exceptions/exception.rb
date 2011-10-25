module DBGeni

  class NoLoggerLocation           < Exception; end
  class MigrationDirectoryNotExist < Exception; end
  class MigrationFilenameInvalid   < Exception; end
  class MigrationFileNotExist      < Exception; end
  class MigrationAlreadyApplied    < Exception; end
  class MigrationNotApplied        < Exception; end
  class MigrationApplyFailed       < Exception; end
  class MigrationContainsErrors    < Exception; end
  class MigrationNotOutstanding    < Exception; end

  class EnvironmentNotExist        < Exception; end

  class ConfigFileNotExist         < Exception; end
  class ConfigAmbiguousEnvironment < Exception; end
  class ConfigFileNotSpecified     < Exception; end
  class ConfigSyntaxError          < Exception; end

  class NoEnvironmentSelected      < Exception; end

  ## Initializer

  # If an attempt is made to load an initializer that doesn't exist
  class NoInitializerForDBType      < Exception; end
  # If the initializer is not corretly defined, this will be raise.
  class InvalidInitializerForDBType < Exception; end

  ## Connectors
  class NoConnectorForDBType        < Exception; end
  class InvalidConnectorForDBType   < Exception; end

  ## Migrators
  class NoMigratorForDBType         < Exception; end
  class InvalidMigratorForDBType    < Exception; end

  class DatabaseAlreadyInitialized  < Exception; end
  class DatabaseNotInitialized      < Exception; end
  class DBGeni::DatabaseNotSpecified < Exception; end
  class NoOutstandingMigrations     < Exception; end
  class NoAppliedMigrations         < Exception; end

  ## code
  class UnknownCodeType             < Exception; end
  class CodeModuleCurrent           < Exception; end
  class CodeApplyFailed             < Exception; end
  class CodeFileNotExist            < Exception; end
  class CodeDirectoryNotExist       < Exception; end
  class NoOutstandingCode           < Exception; end
  class NoCodeFilesExist            < Exception; end

  class DBGeni::DBCLINotOnPath      < Exception; end

end
