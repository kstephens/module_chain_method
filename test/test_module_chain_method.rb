require 'helper'

require 'module/chain_method'

class TestModuleChainMethod < Test::Unit::TestCase
  should "handle Foo#foo and Foo#bar as expected" do
    f = Module::ChainMethod::Test::Foo.new
    f.foo
    f.bar
    assert_equal(f.instance_variable_get("@calls"), [ "Foo#foo", "Foo#bar" ])
  end

  should "handle Foo#foo and Foo#bar with aliases for *_without_MyMixin" do
    Module::ChainMethod::Test::Foo.class_eval do
      include Module::ChainMethod::Test::MyMixin
    end
    assert_equal( 
                 [ "MyMixin.included Module::ChainMethod::Test::Foo" ],
                 Module::ChainMethod::Test::MyMixin.instance_variable_get("@calls")
                 )

    f = Module::ChainMethod::Test::Foo.new
    f.foo
    f.bar
    assert_equal(
                 [ "MyMixin#foo", "Foo#foo", "Foo#bar" ],
                 f.instance_variable_get("@calls")
                 )
                 
  end

  should "handle multiple includes" do
    Module::ChainMethod::Test::Foo.class_eval do
      include Module::ChainMethod::Test::MyMixin
    end
    assert_equal( 
                 [ 
                  "MyMixin.included Module::ChainMethod::Test::Foo",
                  "MyMixin.included Module::ChainMethod::Test::Foo",
                 ],
                 Module::ChainMethod::Test::MyMixin.instance_variable_get("@calls")
                 )

    f = Module::ChainMethod::Test::Foo.new
    f.foo
    f.bar
    assert_equal(
                 [ "MyMixin#foo", "Foo#foo", "Foo#bar" ],
                 f.instance_variable_get("@calls")
                 )
                 
  end
end 


######################################################################


class Module
  module ChainMethod
    module Test
      module MyMixin
        def self.included target
          super
          (@calls ||= [ ]) << "MyMixin.included #{target.inspect}"
        end
        include ::Module::ChainMethod
        
        def foo
          (@calls ||= [ ]) << "MyMixin#foo"
          foo_without_MyMixin
        end
        
        def bar
          (@calls ||= [ ]) << "MyMixin#bar"
        end
        
        chain_method :foo
      end
      
      class Foo
        def foo
          (@calls ||= [ ]) << "Foo#foo"
        end
        
        def bar
          (@calls ||= [ ]) << "Foo#bar"
        end
      end
      
    end
  end
end

