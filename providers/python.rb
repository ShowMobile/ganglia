

action :enable do

  #python module

  directory '/usr/lib/ganglia/python_modules' do
    recursive true
  end

  template "/usr/lib/ganglia/python_modules/#{new_resource.module_name}.py" do
    source "ganglia/#{new_resource.module_name}.py.erb"
    owner "root"
    group "root"
    mode "644"
    variables :options => new_resource.options
    notifies :restart, "service[ganglia-monitor]"
  end

  #configuration

  directory '/etc/ganglia/conf.d' do
    recursive true
  end

  template "/etc/ganglia/conf.d/#{new_resource.module_name}.pyconf" do
    source "ganglia/#{new_resource.module_name}.pyconf.erb"
    owner "root"
    group "root"
    mode "644"
    variables :options => new_resource.options
    notifies :restart, "service[ganglia-monitor]"
  end

end

action :disable do

  file "/usr/lib/ganglia/python_modules/#{new_resource.module_name}.py" do
    action :delete
    notifies :restart, "service[ganglia-monitor]"
  end

  file "/etc/ganglia/conf.d/#{new_resource.module_name}.pyconf" do
    action :delete
    notifies :restart, "service[ganglia-monitor]"
  end

end
