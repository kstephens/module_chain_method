  require 'module/chain_method' # Module::ChainMethod

  module MyMixin
    def self.included target
      super
      $stderr.puts "MyMixin.included #{target}"
    end		 
    include ::Module::ChainMethod

    def foo
      puts "MyMixin#foo"
      foo_without_MyMixin
    end
    # Prepares method #foo for chaining.
    chain_method :foo

    def bar
      puts "MyMixin#bar"
    end
  end
      
  class Foo
    def foo
      puts "Foo#foo"
    end
        
    def bar
      puts "Foo#bar"
      super rescue nil
    end
  end

  f = Foo.new
  f.foo
  f.bar
  puts 

  Foo.send(:include, MyMixin)
  f.foo
  f.bar
