module CapistranoDeploy
  module Full
    def self.load_into(configuration)
      configuration.load do
        namespace :deploy do
          desc 'Full deployment.  Update, migrate, precompile assets and restart.'
          task :full do
            update
            migrate
            assets.precompile
            restart
          end
        end
      end
    end
  end
end

