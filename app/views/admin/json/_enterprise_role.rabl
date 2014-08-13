object @enterprise_role

attributes :id, :user_id, :enterprise_id

node :user_email do |enterprise_role|
  enterprise_role.user.email
end

node :enterprise_name do |enterprise_role|
  enterprise_role.enterprise.name
end
