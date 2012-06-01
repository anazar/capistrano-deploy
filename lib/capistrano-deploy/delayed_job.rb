module CapistranoDeploy
  module DelayedJob
    def self.load_into(configuration)
      configuration.load do
        namespace :delayed_job do
          desc 'Start Delayed Job'
          task :start, :roles => :app do
            run "cd #{deploy_to} && RAILS_ENV=#{rails_env} script/delayed_job start"
          end

          desc 'Stop Delayed Job'
          task :stop, :roles => :app do
            run "cd #{deploy_to} && RAILS_ENV=#{rails_env} script/delayed_job stop"
          end
        end
      end
    end
  end
end
