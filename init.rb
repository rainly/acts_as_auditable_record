require 'acts_as_auditable_record'
require 'acts_as_auditable_record/audit_comparator'

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it
ActiveRecord::Base.class_eval do
  include Model::Acts::AuditableRecord
end