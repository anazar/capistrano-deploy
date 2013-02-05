module CapistranoDeploy
  module PassengerRolling
    def self.load_into(configuration)
      configuration.load do
        namespace :passenger_rolling do
          desc 'Restart passenger'
          task :restart, :except => { :no_release => true }, :once => true do
            find_servers(:roles => :app).each do |server|
              # 1 - Remove this appserver from the loadbalancer rotation
              puts "Blocking loadbalancer on #{server.host}"
              run "sudo mv /etc/httpd/conf.d/subro.acdcorp.com.conf /etc/httpd/conf.d/subro.acdcorp.com.conf.disabled", :hosts => server.host
              run "sudo mv /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf.disabled /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf", :hosts => server.host
              run "sudo /etc/init.d/httpd graceful", :hosts => server.host
              #puts "Sleeping for 90 seconds until LB notices #{server.host} is down"
              sleep(5)

              # 2 - Restart this appserver
              puts "Waiting for passenger to start on #{server.host}"
              run "touch #{deploy_to}/tmp/restart.txt", :hosts => server.host
              run "curl https://localhost --header 'Host: subro.acdcorp.com' -ks > /dev/null", :hosts => server.host

              # 3 - Unblock the laodbalancer
              puts "Unblocking loadbalancer on #{server.host}"
              run "sudo mv /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf /etc/httpd/conf.d/proxy_subro.acdcorp.com.conf.disabled", :hosts => server.host
              run "sudo mv /etc/httpd/conf.d/subro.acdcorp.com.conf.disabled /etc/httpd/conf.d/subro.acdcorp.com.conf", :hosts => server.host
              run "sudo /etc/init.d/httpd graceful", :hosts => server.host              
              unless servers.last == server
                puts "Sleeping for 5 seconds until LB notices #{server.host} is up again"
                sleep(5)
              end
            end
          end
        end
      end
    end
  end
end
