require 'test/unit'
require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'active_support'
require 'active_support/breakpoint'

require File.dirname(__FILE__) + '/../lib/acts_as_auditable_record'
require File.dirname(__FILE__) + '/../lib/acts_as_auditable_record/audit_comparator'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

config = config.symbolize_keys

driver = config[:mysql]

ActiveRecord::Base.establish_connection(driver)

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")

#ActiveRecord::Base.connection.recreate_database driver[:database]  #TODO: find out why this is failing for mysql 
#If the test is run more than once, you will need to comment this line or wrap it in an begin-rescue block or fix the above line.
#ActiveRecord::Base.logger.silence { load(File.dirname(__FILE__) + "/schema.rb") }

Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"

$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

ActiveRecord::Base.class_eval do
  include Model::Acts::AuditableRecord
end

class Test::Unit::TestCase #:nodoc:
  
  def self.fixtures(*args)
    Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, args)
  end
  
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false

end 