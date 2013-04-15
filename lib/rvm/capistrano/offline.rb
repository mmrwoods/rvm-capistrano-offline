require 'rvm/capistrano'

# taken directly from rvm capistrano
# defined outside a namespace to allow use from any
def rvm_task(name,&block)
  if fetch(:rvm_require_role,nil).nil?
    task name, &block
  else
    task name, :roles => fetch(:rvm_require_role), &block
  end
end

module Capistrano
  Configuration.instance(true).load do

    # take note of the default rvm shell so we can
    # toggle between it and the rvm install shell
    set :rvm_default_shell, fetch(:default_shell)

    def with_rvm_install_shell
      set :default_shell, fetch(:rvm_install_shell)
      yield
      set :default_shell, fetch(:rvm_default_shell)
    end

    namespace :rvm_offline do

      desc "Packages RVM and ruby archives to vendor/rvm."
      rvm_task :pack do
        # TODO: split into two tasks
        # TODO: warn and exit if no local rvm installation
        # FIXME: currently updates the local rvm installation, without warning
        vendor_path = "#{Dir.pwd}/vendor"
        run_locally "rvm cleanup archives"
        run_locally "rvm cleanup sources"
        run_locally "rvm get #{rvm_install_type}"
        run_locally "rvm fetch #{rvm_ruby_string}"
        run_locally "mkdir -p #{vendor_path}/rvm/archives"
        run_locally "rm -f #{vendor_path}/rvm/archives/*"
        run_locally "cp $rvm_path/archives/* #{vendor_path}/rvm/archives/"
        puts "RVM archives packaged to #{vendor_path}/rvm/archives"
      end

      desc "Uploads packaged RVM and ruby archives to servers."
      rvm_task :upload do
        with_rvm_install_shell do
          sudo "mkdir -p #{shared_path}/rvm/archives"
          sudo "chown -R #{user} #{shared_path}/rvm"
          Dir.glob("vendor/rvm/archives/*.*").each do |path|
            transfer :up, path, "#{shared_path}/rvm/archives/#{File.basename(path)}"
          end
        end
      end

      desc "Installs RVM from uploaded source archive."
      rvm_task :install do
        with_rvm_install_shell do
          path = capture("ls -t1 #{shared_path}/rvm/archives/*rvm-* | head -n 1", :once => true).chomp
          tmp_dir = "/tmp/#{user}-rvm-install"
          run "rm -rf #{tmp_dir}"
          run "mkdir #{tmp_dir}"
          begin
            run "tar -xzf #{path} -C #{tmp_dir}"
            dir = capture("ls -t1 #{tmp_dir}/ | head -n 1", :once => true).chomp
            # TODO: allow for non-system install
            run "cd #{tmp_dir}/#{dir} && #{sudo} ./install"
            run "source /usr/local/rvm/scripts/rvm"
          ensure
            run "rm -rf #{tmp_dir}"
          end
        end
      end

      namespace :configure do

        desc "Configures RVM to obtain rubies from localhost."
        task :default do
          configure_sftp
          configure_curl
          configure_rvm
        end

        desc "[internal] Configures ssh pubkey auth to allow sftp to localhost."
        rvm_task :configure_sftp do
          # configure pubkey auth
          # FIXME: only works with rsa keys
          with_rvm_install_shell do
            run "if ! test -f ~/.ssh/id_rsa ; then ssh-keygen -f ~/.ssh/id_rsa -N ''; fi"
            run "if ! fgrep \"\$(cat ~/.ssh/id_rsa.pub)\" .ssh/authorized_keys > /dev/null ; then cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys; fi"
            run "chmod 700 ~/.ssh/authorized_keys"
            # add localhost to known hosts
            run "ssh -p #{fetch(:port,22)} -o StrictHostKeyChecking=no localhost echo 'Ok'"
          end
        end

        desc "[internal] Configures curl to use rsa keys for sftp"
        rvm_task :configure_curl do
          # FIXME: only works with rsa keys
          with_rvm_install_shell do
            config_file = "~/.curlrc"
            tmp_file = "/tmp/curlrc"
            run "touch #{config_file}"
            run "cp -p --no-clobber #{config_file} #{config_file}.original"
            run "sed '/^pubkey\|key=.*/d' #{config_file} > #{tmp_file}"
            run "mv #{tmp_file} #{config_file}"
            run "echo \"key=/home/#{user}/.ssh/id_rsa\" >> #{config_file}"
            run "echo \"pubkey=/home/#{user}/.ssh/id_rsa.pub\" >> #{config_file}"
            # FIXME: disables peer verification for *all* curl requests by this user on the servers
            run "echo insecure >> #{config_file}"
          end
        end

        desc "[internal] Configures rvm to obtain rubies from localhost via sftp."
        rvm_task :configure_rvm do
          # TODO: support ruby versions other than MRI 1.9
          # FIXME: overwrites rather than modifies rvm user config file on servers
          archives_url = "sftp://#{user}@localhost:#{fetch(:port,22)}#{shared_path}/rvm/archives"
          with_rvm_install_shell do
            contents = %{
              ruby_url=#{archives_url}
              ruby_1.9_url=#{archives_url}
              rubygems_url=#{archives_url}
            }.strip.gsub(/^\s+/,'')
            config_file = "/usr/local/rvm/user/db"
            run "cp -p --no-clobber #{config_file} #{config_file}.original"
            put contents, config_file
          end
        end

      end # :configure

    end # :rvm_offline

  end if const_defined? :Configuration

end
