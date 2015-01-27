require "db_sync/version"
require 'db_sync/railtie' if defined?(Rails)
#YAML::ENGINE.yamler = "psych"
module DbSync

  class Configuration
    attr_accessor :sync_tables

    def initializers
      sync_tables = []
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.dump_data
    DbSync.configuration.sync_tables.each do |table_name|    
      location = FileUtils.mkdir_p "#{Rails.root}/db_dump"    
      i = "000"    
      sql  = "SELECT * FROM %s"    
      File.open("#{location.first}/#{table_name}.yml", 'w') do |file|      
        data = ActiveRecord::Base.connection.select_all(sql % table_name.upcase)      
        file.write data.inject({}) { |hash, record|  
          hash["#{table_name}_#{i.succ!}"] = record        
          hash      
        }.to_yaml      
        puts "wrote #{file.path} /"    
      end  
    end
  end

  def self.load_data
    Dir["#{Rails.root}/db_dump/*{yml}"].each do |data_file|    
      load_document(data_file)  
    end
  end

  def self.load_document(filename)
    table_name = File.basename(filename).split(".").first
    sql = "DELETE FROM #{table_name}"
    ActiveRecord::Base.connection.execute(sql)
    
    YAML.load_documents(File.new(Rails.root.join(filename), "r").read).first.values.each do |row| 
      columns =  row.keys
      values = row.values.collect { |v| ActiveRecord::Base.connection.quote(v)}
      sql = "INSERT INTO #{table_name} (\"#{columns.join('","')}\") values (#{values.join(',')})"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
