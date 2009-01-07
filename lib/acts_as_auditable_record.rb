module Model
  module Acts
    module AuditableRecord      
           
      def self.included(mod)
        mod.extend(ClassMethods)
      end     

      # declare the class level helper methods which
      # will load the relevant instance methods
      # defined below when invoked
      module ClassMethods       
        
        def acts_as_auditable_record(opts={})
          
          extend Model::Acts::AuditableRecord::SingletonMethods
          include Model::Acts::AuditableRecord::InstanceMethods
          
          opts.symbolize_keys!          
          
          write_inheritable_attribute :options, opts
          class_inheritable_reader   :options
          
          write_inheritable_attribute :audit_report, String.new           
          class_inheritable_accessor :audit_report

          before_update :audit_changes
        end        
        
      end

      module SingletonMethods
        #Singleton methods here.        
      end
    
       # Adds instance methods.
      module InstanceMethods
        def audit_changes()
          buff = []
          include_attributes_hash = {}
          exclude_attributes_array = []          
          self.audit_report = ''
          unless self.id.nil? #handled just incase the model overrides to call audit_changes on a create.
            existing_record = self.class.find(self.id)
            #put the options into an array and ensure all attribute keys are strings going forward.
            
            #collect any attributes the user wants to exclude.
            options[:except].each{|k,v| exclude_attributes_array.push(k.to_s)} unless options[:except].blank?
            
            #include all when user doesn't spec an only list. 
            if options[:only].blank? 
              existing_record.attributes.each{|k,v| include_attributes_hash[k.to_s]=v}            
            else        
              options[:only][0].each{|k,v| include_attributes_hash[k.to_s]=v}
            end
            
            #if :all was specified, gather and merge any customization the user specified.
            if !options[:all].blank?
              with_opts = {}
              options[:all][0].each {|k,v| with_opts[k.to_s]=v}              
              include_attributes_hash.merge!(with_opts)
            end
            
            #build the report based on the hash built from the logic above.
            include_attributes_hash.each do |attr_key, attr_val| 
              unless exclude_attributes_array.include?(attr_key)              
                format_opts = attr_val if attr_val.class==Hash
                val = AuditComparator.new(existing_record, self, attr_key.to_sym, format_opts ).report_difference()
                buff << "#{val}." if val
              end
            end
            
            self.audit_report = buff
          end
          buff
        end       
      end     
    end 
  end
end
