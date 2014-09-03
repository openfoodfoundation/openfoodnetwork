module SuburbSeeder
	def self.seed_suburbs
		state_id_act = Spree::State.where(abbr: "ACT").first.id
		state_id_nsw = Spree::State.where(abbr: "NSW").first.id
		state_id_nt = Spree::State.where(abbr: "NT").first.id
		state_id_qld = Spree::State.where(abbr: "QLD").first.id
		state_id_sa = Spree::State.where(abbr: "SA").first.id
		state_id_tas = Spree::State.where(abbr: "Tas").first.id
		state_id_vic = Spree::State.where(abbr: "Vic").first.id
		state_id_wa = Spree::State.where(abbr: "WA").first.id

		connection = ActiveRecord::Base.connection()

		puts "-- Seeding Australian suburbs"
		connection.execute("
			INSERT INTO suburbs (postcode,name,state_id,latitude,longitude) VALUES
			($$200$$,$$AUSTRALIAN NATIONAL UNIVERSITY$$,#{state_id_act},-35.277272,149.117136), 
			($$221$$,$$BARTON$$,#{state_id_act},-35.201372,149.095065),
			($$800$$,$$DARWIN$$,#{state_id_nt},-12.801028,130.955789),
			($$801$$,$$DARWIN$$,#{state_id_nt},-12.801028,130.955789);
		")
	end
end
