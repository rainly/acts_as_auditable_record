module Model
  module Acts
    module AuditableRecord
      class AuditComparator      
        # these instance variables get set in the private "is_different" method.
        @before = String.new
        @after = String.new       

        def initialize(existing_object, new_object, attribute, *options)
          @obj=existing_object
          @new_obj=new_object
          @attribute = attribute
          options ||= Array.new
          options = options.compact
          unless options.empty?
            @descriptor = options[0][:descriptor]
            @format_proc = options[0][:format_proc]
            @compare_proc = options[0][:compare_proc]
            @message_proc = options[0][:message_proc]
          end
        end
        
        def report_difference
          get_report if is_different?
        end
        
        #return the attribute name in place of the descriptor if it's null
        def descriptor        
          return @attribute.to_s.humanize if @descriptor.blank?
          return @descriptor        
        end       
        
        #default the formatting to use text(to_s) format        
        def format_proc
          return Proc.new{|d| d.to_s} if @format_proc.blank?
          return @format_proc        
        end
        
        def get_report
          return @message_proc.call(@before, @after) if @message_proc
          return "#{descriptor} changed to: #{format_proc.call @after}" if @before.blank?
          return "#{descriptor} changed from: #{format_proc.call @before} to: Nothing." if @after.blank?
          return "#{descriptor} changed from: #{format_proc.call @before} to: #{format_proc.call(@after)}"
        rescue
          return "Unexpected error reporting difference between #{@before} and #{@after} for #{descriptor}"
        end
      
        private
      
        #returns true if the data is different
        def is_different?
          @before = @obj.send(@attribute)
          @after = @new_obj.send(@attribute)         
          return false if @before.blank? and @after.blank?
          @compare_proc.blank? ? @before != @after : compare_objs
        end
        
        def compare_objs
          @before.blank? && !@after.blank? ||
              !@before.blank? && @after.blank? ||
            @compare_proc.call(@before, @after)
        end
      end
    end
  end
end