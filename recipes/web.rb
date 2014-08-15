directory "/etc/ganglia-webfrontend"

case node['platform']
when "ubuntu", "debian"

  remote_file "/usr/src/ganglia-web-#{node['ganglia']['web']['version']}.tar.gz" do
    puts "Getting Ganglia-Web from: #{node['ganglia']['web']['url']}"
    source node['ganglia']['web']['url']
    checksum node['ganglia']['web']['checksum']
  end

  src_path = "/usr/src/ganglia-web-#{node['ganglia']['web']['version']}"

  directory node['ganglia']['web']['install_path'] do
    owner node['apache']['user']
    group node['apache']['group']
    recursive true
  end

  # these directories are split so that the tree is owned by the right user/group
  %w{ conf dwoo dwoo/compiled dwoo/compiled dwoo/cache }.each do |d|
    directory "#{node['ganglia']['web'][:run_dir]}/#{d}" do
      owner node['apache']['user']
      group node['apache']['group']
      recursive true
    end
  end

  execute "untar-ganglia-web" do
    cwd "/usr/src"
    command "tar zxvf ganglia-web-#{node['ganglia']['web']['version']}.tar.gz -C #{node['ganglia']['web']['install_path']} --strip=1"
    creates "#{node['ganglia']['web']['install_path']}/index.php"
  end

  web_app "ganglia" do
    server_name node['ganglia']['web']['aliases'].first
    server_aliases node['ganglia']['web']['aliases']
  end
  apache_site "ganglia" do
    enable true
    notifies :restart, "service[apache2]"
  end

when "redhat", "centos", "fedora"
  package "httpd"
  package "php"
  include_recipe "ganglia::source"
  include_recipe "ganglia::gmetad"

  execute "copy web directory" do
    command "cp -r web /var/www/html/ganglia"
    creates "/var/www/html/ganglia"
    cwd "/usr/src/ganglia-#{node['ganglia']['version']}"
  end
end

xml_port = if node['ganglia']['enable_two_gmetads'] then
             node['ganglia']['two_gmetads']['xml_port']
           else
             node['ganglia']['gmetad']['xml_port']
           end
template "/etc/ganglia-webfrontend/conf.php" do
  source "webconf.php.erb"
  mode "0644"
  variables( :xml_port => xml_port )
end

service "apache2" do
  service_name "httpd" if platform?( "redhat", "centos", "fedora" )
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
