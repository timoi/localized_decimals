module LocalizedDecimals
  
  # Redefines how rails writes decimal and float attributes so that
  # I18n is used.
  module ActiveRecord
    def self.included( base )
      base.send :extend, ClassMethods
      
      base.class_eval do
        class << self
          alias_method_chain :define_write_method, :conversion
        end
      end
    end
    
    module ClassMethods
      
      def define_write_method_with_conversion( attr_name )
        if [ :float, :decimal ].include? columns_hash[ attr_name.to_s ].type
          
          method_definition = <<-END_OF_EVAL
            def #{ attr_name }=( raw_value )
              if raw_value.class == String
                processed_value = raw_value.tr( '#{ I18n.t(:'number.format.separator') }', '.' )
 
                if processed_value.to_d.to_s == processed_value
                  raw_value = processed_value
                end
              end
 
              write_attribute( '#{ attr_name }', raw_value )
            end
          END_OF_EVAL
          
          evaluate_attribute_method attr_name, method_definition, "#{ attr_name }="
        else
          define_write_method_without_conversion( attr_name )
        end
      end
    end
  end
  
  module InstanceTag
    def self.included( base )
      base.send :extend, ClassMethods
      
      base.class_eval do
        class << self
          alias_method_chain :value_before_type_cast, :conversion
        end
      end
    end
    
    module ClassMethods
      def value_before_type_cast_with_conversion( object, method_name )
        raw_value = value_before_type_cast_without_conversion( object, method_name )
        
        casted_value = value( object, method_name )
        
        if [ Float, BigDecimal ].include?( casted_value.class ) && casted_value.to_s == raw_value
          raw_value = raw_value.tr( '.', I18n.t(:'number.format.separator'))
        end
        
        return raw_value
      end
    end
  end
end


ActiveRecord::Base.send( :include, CustomNumberFormat::ActiveRecord )
ActionView::Helpers::InstanceTag.send( :include, CustomNumberFormat::InstanceTag )