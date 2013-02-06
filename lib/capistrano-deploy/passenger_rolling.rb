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
                logger.info "Blocking loadbalancer on #{server.host}"
                run "sudo mv /etc/httpd/conf.d/subro.acdcorp.com.conf /etc/httpd/conf.d/subro.acdcorp.com.conf.disabled", :hosts => server.host
                run "sudo mv /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf.disabled /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf", :hosts => server.host
                run "sudo /etc/init.d/httpd graceful", :hosts => server.host
                #puts "Sleeping for 5 seconds until LB notices #{server.host} is down"
                sleep(5)
              end

              # 2 - Restart this appserver
              logger.info "Waiting for passenger to start on #{server.host}"
              run "touch #{deploy_to}/tmp/restart.txt", :hosts => server.host
              run("curl #{server.curl_url} -ks > /dev/null", :hosts => server.host) if server.curl_url

              # 3 - Unblock the laodbalancer
              if 'production' == rails_env              
                logger.info "Unblocking loadbalancer on #{server.host}"
                run "sudo mv /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf.disabled", :hosts => server.host
                run "sudo mv /etc/httpd/conf.d/subro.acdcorp.com.conf.disabled /etc/httpd/conf.d/subro.acdcorp.com.conf", :hosts => server.host
                run "sudo /etc/init.d/httpd graceful", :hosts => server.host 
                sleep(5)
              end

            end
          end
        end

        after 'deploy:restart', 'passenger_rolling:restart'        
      end
    end
  end
end
