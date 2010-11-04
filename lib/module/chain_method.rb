
class Module
  module ChainMethod
    def self.included target
      # $stderr.puts "ChainMethod #{self.inspect}.included #{target}"
      super
      target.extend(ClassMethods)  if Class  === target 
      target.extend(ModuleMethods) if Module === target
      if target.method_defined?(:included)
        target.send(:alias_method, :included_without_ChainMethod, :included)
      end
    end

    module ModuleMethods 
      def included target
        # $stderr.puts "ChainMethod::ModuleMethods #{self.inspect}.included #{target}"
        super
        self.included_without_ChainMethod(target) if self.respond_to?(:included_without_ChainMethod)
        # $stderr.puts "#{target.inspect}.ancestors = #{target.ancestors.inspect}"
        target.extend(self.ClassMethods)  if Class  === target && defined?(self.ClassMethod)
        target.extend(self.ModuleMethods) if Module === target && defined?(self.ModuleMethods)
        chain_methods! target
      end

      def chain_methods suffix = nil
        # $stderr.puts "ChainMethod::ModuleMethods #{self.inspect}.chain_methods #{suffix.inspect}"
        @chain_methods_suffix = suffix if suffix 
        @chain_methods ||= [ ]
      end

      def _chain_methods_suffix
        @chain_methods_suffix ||= self.name.sub(/.*::/, '').freeze
        @_chain_methods_suffix ||= @chain_methods_suffix.to_s.sub(/[^a-z0-9_]/i, '_').freeze
      end

      def chain_method *selectors
        # $stderr.puts "ChainMethod::ModuleMethods #{self.inspect}.chain_method #{selectors.inspect}"
        chain_methods.push(*selectors.map{|m| m.to_sym}).uniq!
        # $stderr.puts "chain_selectors = #{chain_methods.inspect}"
        self
      end

      # NOT THREAD-SAFE!
      def prepare_methods!
        @chain_methods_prepared ||= [ ] 
        # $stderr.puts "ChainMethod::ModuleMethods #{self.inspect}.prepare_methods!"

        suffix = _chain_methods_suffix

        target = self

        # $stderr.puts "  BEFORE: #{(target.instance_methods.sort - Object.methods).inspect}"

        chain_methods.each do | selector |
          next if @chain_methods_prepared.include?(selector)
          @chain_methods_prepared << selector

          without_selector = _map_selector(selector, "_without_#{suffix}")
          with_selector    = _map_selector(selector, "_with_#{suffix}")
          # $stderr.puts "  #{target.inspect}.alias #{without_selector.inspect} #{selector.inspect}"
          unless target.method_defined?(with_selector)
            target.send(:alias_method, with_selector, selector)
          end
        end
        # $stderr.puts "  AFTER:  #{(target.instance_methods.sort - Object.methods).inspect}"

        self
      end

      def chain_methods! target
        # $stderr.puts "ChainMethod::ModuleMethods #{self.inspect}.chain_methods! #{target.inspect}"
        prepare_methods!
        suffix = _chain_methods_suffix

        # $stderr.puts "  BEFORE: #{(target.instance_methods.sort - Object.methods).inspect}"
        chain_methods.each do | selector |
          without_selector = _map_selector(selector, "_without_#{suffix}")
          with_selector    = _map_selector(selector, "_with_#{suffix}")
          # $stderr.puts "  #{target.inspect}.alias #{without_selector.inspect} #{selector.inspect}"
          unless target.method_defined?(without_selector)
            target.send(:alias_method, without_selector, selector)
          end
          target.send(:alias_method, selector, with_selector)
        end
        # $stderr.puts "  AFTER:  #{(target.instance_methods.sort - Object.methods).inspect}"
      end
      
      def _map_selector selector, suffix
        selector.to_s.
          sub(/\A([a-z0-9_]+)([^a-z0-9_]?)\Z/i) { | m | $1 + suffix + $2 }.
          to_sym
      end
    end
  end
end



