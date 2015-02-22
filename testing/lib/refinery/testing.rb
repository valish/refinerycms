require 'refinerycms-core'
require 'rspec-rails'
require 'factory_girl'

class FakeUser < ActiveRecord::Base
  include Refinery::Core::UserContext
end

class FakeUserMigration < ActiveRecord::Migration
  def change
    create_table :fake_users do |t|
      t.string :username
      t.string :email
      t.string :password
    end
  end
end
module Refinery
  autoload :TestingGenerator, 'generators/refinery/testing/testing_generator'

  module Testing
    class << self
      def root
        @root ||= Pathname.new(File.expand_path('../../../', __FILE__))
      end

      # Load the factories of all currently loaded extensions
      def load_factories
        Refinery.extensions.each do |extension_const|
          if extension_const.respond_to?(:factory_paths)
            extension_const.send(:factory_paths).each do |path|
              FactoryGirl.definition_file_paths << path
            end
          end
        end
        FactoryGirl.find_definitions

        if FactoryGirl.factories.none? { |f| f.name == :refinery_user}
          FakeUserMigration.migrate(:up) unless FakeUser.table_exists?
          FactoryGirl.define do
            factory :refinery_user, class: FakeUser
          end
        end
      end
    end

    require 'refinery/testing/railtie'

    autoload :ControllerMacros, 'refinery/testing/controller_macros'
    autoload :FeatureMacros, 'refinery/testing/feature_macros'
  end
end
