# encoding: UTF-8
# migr8er.rb - Script to obtain table information from a MySQL database
#
require "./lib/migrater/version"
require "./lib/migrater_globals"
require 'ruby-debug'
require 'mysql2'
$debug = true

module Migrater 
  # Migrater is the object that stores a master array
  # which contains the database name, table names and table data
  # extracted from a MySQL database in order to write a schema 
  # that can be used in rails
  #
  # This array will contained mixed objects:
  #
  # Array  = contains only a single database name
  # String = contains a single table name
  # Hash   = contains a set of fields and attributes 
  #          for each table column
  # 
  class MasterSchema
    attr_accessor :master_ary, :dbname, :tname, :schema_buf
    
    def initialize
      @master_ary = []
      @tname = String.new
      @dbname = []
      @schema_buf = String.new
    end  

    # this method is passed a text file pointer
    # that points to the start of a database 
    # dump of a database and all of the database's
    # table definitions, to sollect the data to 
    # write a proper rails migration
    def read_tables_from_file(f)
      hsh = Hash.new                     # hash to contain each table's columns and attributes

      while(line = f.gets) 
        if /Database = /.match(line)
          @dbname << line.split(' = ')[1].strip # get database name and remove newline
          @master_ary << @dbname
          
        elsif /Table = /.match(line)
          @tname = line.split(' = ')[1].strip # get table and remove newline char
          @master_ary << @tname
        elsif /Field = /.match(line)
          hsh['field'] = line.split(' = ')[1].strip unless line.split(" = ")[1].strip.empty?
          
        elsif /Type = /.match(line)
          hsh['type'] = line.split(' = ')[1].strip unless line.split(" = ")[1].strip.empty?
          
        elsif /Null = /.match(line)
          hsh['null'] = line.split(' = ')[1].strip unless line.split(" = ")[1].strip.empty?
          
        elsif /Key = /.match(line)
          hsh['key'] = line.split(' = ')[1].strip unless line.split(" = ")[1].strip.empty?
          
        elsif /Default = /.match(line)
          hsh['default'] = line.split(' = ')[1].strip unless line.split(" = ")[1].strip.empty?
          
        elsif /Extra = /.match(line)
          hsh['extra'] = line.split(' = ')[1].strip unless line.split(" = ")[1].strip.empty?
          @master_ary << hsh    # assign this column's hash to the master array
          hsh = {}              # clear out the hash and start again
          
        else
          puts "No match found for line: #{line}"
        end
      end
      hsh        # return the completed hash
    end

    # use this method for varchar and int types
    # this allows us to set a :limit => xxx
    # to match the original mysql data definition
    def check_limit(str)
      if str.include?('(')
        arr = str.split("(")
        limit = arr[1].chomp(')')
        ", :limit => #{limit}"
      else
        nil
      end
    end
    
    # see if a default exists for this type
    # if so, return the default string
    def check_default(str)
      if str.strip != ""
        str = ", :default => #{str}"  
      end
      str
    end
    
    # extract enum values and assign them to
    # an array tagged by ":limit => []"
    def check_enum(str)
      buf = String.new
      ar = (str.split('('))
      ar[1].chomp!(')')
      limit = ar[1].split(',')
      buf << ", :limit => ["
      limit.each do |option|
        buf << ':' << option << ','
      end
      buf.chomp!(',')
      buf << ']'
    end
    
    def check_null(str)
      if((str != nil) || (str != ""))  
        if str.match(/YES/)
          str = ", :null => true"
        elsif str.match(/NO/)
          str = ", :null => false"
        end
      end  
      str
    end

    # we should never get here, as we remove id columns
    # and rails inserts them automatically
    def check_key(str)
      if str.match(/PRI/)
        ""
      end
    end
    
    def check_default(str)
      if str
        if (str.strip != "")
          str = ", :default => #{str}"  
        end      
      end  
      str
    end
    
    def check_extra(str)
      # ignore for now until I find useful documentation
    end
    
    def process_hash(obj)
      buf = String.new
      case obj['type']
        when /varchar/
          buf << "    t.string   \"#{obj['field']}\""
          buf << check_limit(obj['type'])
        when /\Achar/
          buf << "    t.string   \"#{obj['field']}\""
          buf << check_limit(obj['type'])       
        when /int/
          if obj['field'] == "id"
            puts "skipping id for rails..."
          else  
            buf << "    t.integer  \"#{obj['field']}\""                        
            buf << check_limit(obj['type'])
          end
        
        when /tinyint/
          buf << "    t.boolean  \"#{obj['field']}\""                        
        when /text/
          buf << "    t.text     \"#{obj['field']}\""
        when /date/
          buf << "    t.date     \"#{obj['field']}\""       
          obj['default'] = "Time.now"
        when /datetime/
          buf << "    t.datetime \"#{obj['field']}\""                        
          obj['default'] = "Time.now"
        when /time/
          buf << "    t.time     \"#{obj['field']}\""                        
          obj['default'] = "Time.now"
        when /timestamp/
          buf << "    t.timestamp \"#{obj['field']}\""
          obj['default'] = "Time.now"
        when /decimal/
          buf << "    t.decimal  \"#{obj['field']}\""                        
        when /float/
          buf << "    t.float    \"#{obj['field']}\""                        
        when /enum/
          buf << "    t.enum     \"#{obj['field']}\""                        
        when /blob/
          buf << "    t.binary   \"#{obj['field']}\""
      end  
      if obj['field'] != "id"
        buf << check_null(obj['null'])
      end  
      if obj['default']
        if obj['field'] != "id"        
          buf << check_default(obj['default'])        
        end  
      end
      buf << "\n"     
      puts buf
      buf
    end
    
    # write out the new schema file for use with rails
    def write_schema(f)
      time = SecondString.new
      subsequent_table = false # boolean false until first table
      
      @schema_buf = String.new
      @schema_buf << $schema_preamble
      @schema_buf << "\#\n\# Database: #{@dbname}\n\#\n"      
      @schema_buf << "ActiveRecord::Schema.define(:version => #{time.today}) do\n"
      @schema_buf << "  create table \"#{@tname}\", :force => true do |t|"
       
      puts "@master_ary = #{@master_ary}"
      
      @master_ary.each do |obj|
        case obj
          when Array
            if $debug
              puts "Database = #{obj[0]}"
            end

          when String
            if $debug
              puts "Table = #{obj}"
            end
            # if table has been processed, 
            # append an end statement to @schema_buf           
            if subsequent_table
              @schema_buf << "  end\n\n"
              if obj == "schema_info"
                @schema_buf << "  create_table \"#{obj}\", :force => true do |t|\n"                
              else
                @schema_buf << "  create_table \"#{obj}\", :force => true do |t|"
              end  
            else  
              subsequent_table = true
            end

          when Hash
            @schema_buf += process_hash(obj)
        end
      end # end master_ary.each
      
      @schema_buf << "  end\nend\n"
      if $debug
        puts @schema_buf
      end
      f.write(@schema_buf)
    end  
  end
  
  class SecondString
    attr_accessor :today
    
    def initialize
      today = Time.now.to_s.split
      @today = today[0].split("-").join + today[1].split(":").join
    end
    
  end

  # The Fields class collects the information from
  # the MySQL database table in order to write the 
  # schema file correctly
  class Fields
    # :field = name, :type = int,varchar,datetime, :null = nulls
    # allowed, :key = ?, :default = default value, :extra=?
    attr_accessor :schema, :fields_ary
    
    def initialize
      @fields_ary |= []
      @schema |= {}
    end
    
    def load(hsh)
      # assign hash members unless attributes are empty strings      
      @schema = hsh unless hsh.empty?
      @fields_ary << @schema      
    end
  end

  class SchemaReader
    attr_accessor :host, :user, :pword, :dbname, :tname
    
    def initialize(h,u,p,db)
      @host = h
      @user = u
      @pword = p
      @dbname = db 
      @tname = String.new
    end
  end
    
  # The Table class stores the title of the table along with 
  # a hash of attributes for each field in the table
  class Table
    attr_accessor :name, :table_fields
    
    def initialize(n = 'table_name')
      @table_fields = []
      @name = n
    end
    
    # add a hash of fields and values to the table_fields array
    def add_fields(fields)
      @tables_fields << fields
    end   
  end
  
  class DBConn
    attr_accessor :host, :user, :password, :database, :conn
  
    def initialize(h = 'localhost', u = 'sdownie', p = 'sailing', d = 'wm')
      @host = h
      @user = u 
      @password = p
      @database = d
      @conn = nil
    end

    def connect_to_db
      @conn = Mysql2::Client.new(@host, @user, @pword, @dbname )            
    end
        
    def get_commands(arr)
      0.upto arr.length - 1 do|x|
        case arr[x]
          # print help message and bail out
          when /\A-h\Z/, /\A--help\Z/
            puts $preamble
            abort
          when /\A-v\Z/, /\A--version\Z/

            puts $version
            abort
          # override defaults if given command line options
          when /\A-s\Z/, /\A--server\Z/      
            @host = arr[x+=1]     # set server name and skip ahead 
          when /\A-u\Z/, /\A--user\Z/                            
            @user = arr[x+=1]     # set user name and skip ahead     
          when /\A-p\Z/, /\A--password\Z/                       
            @password = arr[x+=1] # set user password and skip ahead  
          when /\A-d\Z/, /\A--database\Z/                      
            @database = arr[x+=1] # set database name and skip ahead 
          else
            abort("Unknown command option: #{arr[x]}, please correct and try again.")
        end
      end
    end
    
  end
end

