namespace :migrate_paperclip do
  desc 'Migrate the paperclip attachments'
  task move_attachments: :environment do
    Rails.application.eager_load!

    models = ActiveRecord::Base.descendants.reject(&:abstract_class?)

    models.each do |model|
      puts 'Checking Model [' + model.to_s + '] for Paperclip attachment columns ...'

      errs = []
      err_ids = []

      attachments = model.column_names.map do |c|
        Regexp.last_match(1) if c =~ /(.+)_file_name$/
      end.compact

      attachments.each do |attachment|
        migrate_attachment(attachment, model, errs, err_ids)
      end

      next if errs.empty?

      puts ''
      puts 'Errored attachments:'
      puts ''

      errs.each do |err|
        puts err
      end

      puts ''
      puts 'Errored attachments list of IDs (use for SQL statements)'
      puts err_ids.join(',')
      puts ''
    end
  end
end

private

def migrate_attachment(attachment, model, errs, err_ids)
  model.where.not("#{attachment}_file_name": nil).find_each do |instance|

    bucket = Rails.env.production? ? ENV['S3_BUCKET_NAME'] : ENV['S3_BUCKET_NAME_DEV']
    region = ENV['S3_REGION']

    instance_id = instance.id
    filename = instance.send("#{attachment}_file_name")
    extension = File.extname(filename)
    content_type = instance.send("#{attachment}_content_type")
    original = CGI.unescape(filename.gsub(extension, "_original#{extension}"))

    puts '  [' + model.name + ' (ID: ' +
         instance_id.to_s + ')] ' \
         'Copying to ActiveStorage location: ' + original

    instance_path = instance_id.to_s.rjust(9, '0')
    instance_path = instance_path.scan(/.{1,3}/).join('/')

    url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{model.name.downcase.pluralize}/#{attachment.pluralize}/#{instance_path}/original/#{filename}"

    begin
      instance.send(attachment.to_sym).attach(
        io: open(url),
        filename: filename,
        content_type: content_type
      )
    rescue StandardError => e
      puts '    ... error! ...'
      errs.push("[#{model.name}][#{attachment}] - #{instance_id} - #{e}")
      err_ids.push(instance_id)
    end
  end
end
