case node['platform_family']
when "redhat", "centos", "fedora"
  %w{ apr-devel libconfuse-devel expat-devel rrdtool-devel }.each do |p|
    package p
  end
when "debian"
  %w{ librrd-dev librrd4 libapr1-dev libconfuse-dev libexpat1-dev }.each do |p|
    package p
  end
end

remote_file "/usr/src/ganglia-#{node['ganglia']['version']}.tar.gz" do
  puts "Getting Ganglia-GMetad from: #{node[:ganglia][:uri]}"
  source node['ganglia']['uri']
  checksum node['ganglia']['checksum']
end

src_path = "/usr/src/ganglia-#{node['ganglia']['version']}"

execute "untar ganglia" do
  command "tar xzf ganglia-#{node['ganglia']['version']}.tar.gz"
  creates src_path
  cwd "/usr/src"
end

execute "configure ganglia build" do
  command "./configure --sysconfdir=/etc/ganglia --prefix=/usr"
  creates "#{src_path}/config.log"
  cwd src_path
end

execute "build ganglia" do
  command "make"
  creates "#{src_path}/gmond/gmond"
  cwd src_path
end

execute "install gmond" do
  command "make install"
  creates "/usr/sbin/gmond"
  cwd src_path
end

execute "install gmetad" do
  command "make install"
  creates "/usr/sbin/gmetad"
  cwd "#{src_path}/gmetad"
end

link "/usr/lib/ganglia" do
  to "/usr/lib64/ganglia"
  only_if do
    node['kernel']['machine'] == "x86_64" and
      platform?( "redhat", "centos", "fedora", "debian" )
  end
  not_if "test -d /usr/lib/ganglia"
end

directory "#{node['ganglia']['mod_path']}/python_modules" do
  owner node['ganglia']['user']
  group node['ganglia']['group']
  recursive true
end

execute "copy python_modules" do
  cwd "#{src_path}/gmond"
  command "cp -r python_modules #{node['ganglia']['mod_path']}"
  creates "#{node['ganglia']['mod_path']}/python_modules"
  only_if "test -d #{node['ganglia']['mod_path']}"
end
