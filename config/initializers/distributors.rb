# YAML distributors config
DISTRIBUTOR_CONFIG = YAML.load(File.read(File.expand_path('../../distributors.yml', __FILE__)))
DISTRIBUTOR_CONFIG.merge! DISTRIBUTOR_CONFIG.fetch(Rails.env, {})
