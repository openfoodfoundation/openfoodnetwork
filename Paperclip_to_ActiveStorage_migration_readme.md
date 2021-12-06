# Migration from Paperclip to ActiveStorage 

Goal:
- Keep downtime to a minimum
- Be able to easily and **quickly** rollback if any problem happens 

## First step: use both libs 

- enable ActiveStorage and add its SQL tables
- add code to use ActiveStorage in addition to current Paperclip code to handle attachments
    - keep code that create/update/delete any Paperclip metadata
    - use the Paperclip key for ActiveStorage files to point to a single file on storage (S3 or other)
    - use ActiveStorage when only accessing attachments (read operations)
    - update tests if needed to use/check ActiveStorage. Add or improve current test to check every operation is done on both paperclip and active storage.
- add rake task to initialize ActiveStorage metadata from Paperclip metadata (and file content)

As a result:
- The only DB migration is creating new ActiveStorages tables
- At this point everything can be rollbacked easily
- Deployment:
    - test on staging
    - backup S3 buckets or any other storage
    - deploy on production. There should be no more downtime than usual, rake task can be started after deployment is complete
    - rollback if anything breaks`

## Second step (at least one or two weeks later?)

- remove any Paperclip code
- delete Paperclip DB tables
- deploy

At this point, code cannot be rollbacked any more without reloading db dumps.