module TestHelper

  require 'dbgeni/connectors/sqlite'
  require 'dbgeni/connectors/oracle'

  TEMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), "temp"))
  SQLITE_DB_NAME  = 'sqlite.db'

  ORA_USER     = 'sodonnel'
  ORA_PASSWORD = 'sodonnel'
  ORA_DB       = 'local11g'

  def helper_sqlite_connection
    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.rm_rf(File.join(TEMP_DIR, SQLITE_DB_NAME))
    connection = DBGeni::Connector::Sqlite.connect(nil, nil, "#{TEMP_DIR}/#{SQLITE_DB_NAME}")
  end

  def helper_sqlite_config
    config = DBGeni::Config.new.load("database_type 'sqlite'
                                      environment('development') {
                                         user     ''
                                         password ''
                                         database '#{TEMP_DIR}/#{SQLITE_DB_NAME}'
                                     }")
  end

  def helper_oracle_connection
    connection = DBGeni::Connector::Oracle.connect(ORA_USER, ORA_PASSWORD, ORA_DB)
  end

  def helper_oracle_config
    config = DBGeni::Config.new.load("database_type 'oracle'
                                      environment('development') {
                                         username '#{ORA_USER}'
                                         password '#{ORA_PASSWORD}'
                                         database '#{ORA_DB}'
                                     }")
  end

  def helper_good_oracle_migration
    FileUtils.rm_rf(File.join(TEMP_DIR, 'migrations', "*.sql"))
    filename ='201108190000_up_test_migration.sql'
    File.open(File.join(TEMP_DIR, 'migrations', filename), 'w') do |f|
      f.puts "select * from dual;"
    end
    DBGeni::Migration.new(File.join(TEMP_DIR, 'migrations'), filename)
  end

  def helper_bad_oracle_migration
    FileUtils.rm_rf(File.join(TEMP_DIR, 'migrations', "*.sql"))
    filename ='201108190000_up_test_migration.sql'
    File.open(File.join(TEMP_DIR, 'migrations', filename), 'w') do |f|
      f.puts "select * from dua;"
    end
    DBGeni::Migration.new(File.join(TEMP_DIR, 'migrations'), filename)
  end

  def helper_empty_oracle_migration
    FileUtils.rm_rf(File.join(TEMP_DIR, 'migrations', "*.sql"))
    filename ='201108190000_up_test_migration.sql'
    File.open(File.join(TEMP_DIR, 'migrations', filename), 'w') do |f|
    end
    DBGeni::Migration.new(File.join(TEMP_DIR, 'migrations'), filename)
  end




end
