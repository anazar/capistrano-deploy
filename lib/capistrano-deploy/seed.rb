module CapistranoDeploy
  module Seed
    def self.load_into(configuration)
      configuration.load do
        set :rake do
          if using_recipe?(:bundle)
            'bundle exec rake'
          else
            'rake'
          end
        end

        namespace :deploy do
          desc 'seed the database'
          task :seed, :roles => :db, :only => {:primary => true} do
            run "cd #{deploy_to} && RAILS_ENV=#{rails_env} #{rake} db:seed" unless 'production' == rails_env
          end

          task :rollback, :roles => :db, :only => {:primary => true} do
            run "cd #{deploy_to} && RAILS_ENV=#{rails_env} #{rake} db:rollback" unless 'production' == rails_env
          end
        end
      end
    end
  end
end
