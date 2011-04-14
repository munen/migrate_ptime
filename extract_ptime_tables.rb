# Extract entries
fp = File.open("entries.csv", "w")

# duration,date,project_id,user,description,task_id,billable
Entry.all.each do |entry|
  begin
    task_id = entry.task.id
  rescue
    task_id = ''
  end
  fp.write([entry.duration, entry.date, entry.project.id, 
            entry.user.name, entry.description, task_id, 
            entry.billable].join(";"))
  fp.write("\n")
end


# Extract projects
fp = File.open("projects.csv", "w")

# description, inactive, project_id
Project.all.each do |project|
  fp.write([project.description, project.inactive.to_s, project.id ].join(";"))
  fp.write("\n")
end


# Extract tasks
#require "ruby-debug"
fp = File.open("tasks.csv", "w")

# name, estimation, project_id, billable, task_id
Task.all.each do |task|
  begin
    project_id = task.project.id
  rescue
    project_id = ''
  end

  unless task.name.empty?
    fp.write([task.name, task.estimation, project_id, task.billable, task.id].join(";"))
    fp.write("\n")
  end
end
