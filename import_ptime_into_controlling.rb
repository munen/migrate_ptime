# Clear database
Project.delete_all
Task.delete_all
Entry.delete_all
User.delete_all

# Import users
#admins = { 'your_old_username' => 'user@example.com' }

#admins.each do |username, email|
#  User.create!(:username => username, :password => 'your_pwd',
#               :email => email) do |user|
#    user.admin=true
#  end
#end

# Load projects into hash indexed by ptime project_id
fp = File.open("projects.csv")
projects = {}

begin
  while line = fp.readline
    description, inactive, id = line.split(";")
    projects[id.strip] = { :description => description, :inactive => inactive }
  end
rescue
  puts "Done reading projects.csv"
end


# Get project shortname and import projects into db
projects.each do |key, project|
  project[:shortname] = project[:description].slice(/\w{3}-\d{3}/).to_s
  if project[:shortname]
    project[:description].gsub!(project[:shortname], "")
    project[:description].gsub!(" - ", "")
  end

  project[:inactive] = project[:inactive].include?("true") ? true : false

  # Do not create projects without shortname
  puts "Migrating project: #{project[:shortname]}"
  if project[:shortname].present?
    project[:new_id] = Project.create!(:shortname => project[:shortname],
                                    :description => project[:description],
                                    :inactive => project[:inactive],
                                    :start => Time.now, :end => Time.now,
                                    :project_state_id => 1).id
  end
end


# Import tasks into db and relate them to projects
fp = File.open("tasks.csv")
tasks = {}

begin
  while line = fp.readline
    name, estimation, project_id, billable, task_id = line.split(";")
    billable = billable.include?("true") ? true : false
    
    if projects[project_id]
      project_id = projects[project_id][:new_id].to_i

      task = Task.create!(:name => name, 
                :estimation => estimation.to_i, 
                :project_id => project_id,
                :billable => billable)

      if project_id > 0
        project = Project.find(project_id)
        project.tasks << task

        tasks[task_id.strip] = { :name => name, 
                  :estimation => estimation.to_i, 
                  :project_id => project_id,
                  :billable => billable,
                  :new_id => task.id }
      end
    end

  end

rescue
  puts "Done reading the tasks.csv"
end


# Import entries 
fp = File.open("entries.csv")

# Entries were possible without associated tasks. Also there are entries with
# associated task_id that are no longer in the db.
dummy_project = Project.create!(:shortname => "dum-001", 
                                :description => "Dummy project for initial import",
                                :start => Time.now, :end => Time.now,
                                :project_state_id => 1)
dummy_task = Task.create!(:name => "dummy", :project_id => dummy_project.id)

begin
  while line = fp.readline
    duration, date, project_id, user, description, task_id, billable = line.split(";")
    billable = billable.include?("true") ? true : false
    
    if projects[project_id]
      project_id = projects[project_id][:new_id].to_i
      begin
        task = Task.find(tasks[task_id][:new_id])
      rescue
        task = dummy_task
      end

      begin
        user_id = User.find_by_username(user).id
      rescue
        user_id = User.find_by_username("dummy").id
      end

      if duration
         duration.gsub!('.', ':')
      else
        duration = "0:00"
      end

      begin
        Entry.create!(:description => description, 
                   :task_id => task.id,
                   :project_id => project_id,
                   :billable => billable,
                   :day => date,
                   :user_id => user_id,
                   :duration_hours => duration)
      rescue
        puts "Task #{description} skipped because the project was missing (probably for being duplicate)"
      end
    end
  end
rescue
  puts "Done reading the entries.csv"
end
