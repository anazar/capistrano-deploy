module CapistranoDeploy
  module PassengerRolling
    def self.load_into(configuration)
      configuration.load do
        namespace :passenger_rolling do
          desc 'Restart passenger'
          task :restart, :except => { :no_release => true }, :once => true do
            find_servers(:roles => :app).each do |server|
              # 1 - Remove this appserver from the loadbalancer rotation
              if 'production' == rails_env
                if healthcheck_path
                  logger.info "Blocking loadbalancer on #{server.host}"
                  run "mv #{healthcheck_path} #{healthcheck_path}.backup", :hosts => server.host
                  sleep(40)
                end
              end

              # 2 - Restart this appserver
              logger.info "Waiting for passenger to start on #{server.host}"
              run "touch #{deploy_to}/tmp/restart.txt", :hosts => server.host
              run("curl #{server.options[:curl_url]} -ks > /dev/null", :hosts => server.host) if server.options.has_key?(:curl_url)

              # 3 - Unblock the laodbalancer
              if 'production' == rails_env   
                if healthcheck_path
                  logger.info "Enabling loadbalancer on #{server.host}"
                  run "mv #{healthcheck_path}.backup #{healthcheck_path}", :hosts => server.host
                  sleep(40)
                end
              end              
            end
          end
        end

        after 'deploy:restart', 'passenger_rolling:restart'        
      end
    end
  end
end
