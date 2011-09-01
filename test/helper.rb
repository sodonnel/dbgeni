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
    config.base_directory = TEMP_DIR
    config
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
    config.base_directory = TEMP_DIR
    config
  end

  def helper_good_oracle_migration
    create_migration_files("select * from dual;")
  end

  def helper_good_sqlite_migration
    create_migration_files("select * from sqlite_master;")
  end

  def helper_bad_oracle_migration
    create_migration_files("select * from dua;\ncreate table foo (c1 integer);")
  end

  def helper_bad_sqlite_migration
    create_migration_files("select * from tab_not_exist;\ncreate table foo (c1 integer);")
  end

  def helper_empty_oracle_migration
    create_migration_files('')
  end

  def helper_empty_sqlite_migration
    helper_empty_oracle_migration
  end

  private

  def create_migration_files(content)
    FileUtils.rm_rf(File.join(TEMP_DIR, 'migrations', "*.sql"))
    filenames = %w(201108190000_up_test_migration.sql 201108190000_down_test_migration.sql)
    filenames.each do |fn|
      File.open(File.join(TEMP_DIR, 'migrations', fn), 'w') do |f|
        f.puts content
      end
    end
    DBGeni::Migration.new(File.join(TEMP_DIR, 'migrations'), filenames[0])
  end

end