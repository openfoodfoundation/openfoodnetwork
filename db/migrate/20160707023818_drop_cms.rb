class DropCms < ActiveRecord::Migration

  # Reverse of CreateCms in 20121009232513_create_cms.rb, including foreign keys defined
  # in 20140402033428_add_foreign_keys.rb

  def up
    drop_table_cascade :cms_sites
    drop_table_cascade :cms_layouts
    drop_table_cascade :cms_pages
    drop_table_cascade :cms_snippets
    drop_table_cascade :cms_blocks
    drop_table_cascade :cms_files
    drop_table_cascade :cms_revisions
    drop_table_cascade :cms_categories
    drop_table_cascade :cms_categorizations
  end

  def down
    text_limit = case ActiveRecord::Base.connection.adapter_name
      when 'PostgreSQL'
        { }
      else
        { :limit => 16777215 }
      end

    # -- Sites --------------------------------------------------------------
    create_table :cms_sites do |t|
      t.string :label,        :null => false
      t.string :identifier,   :null => false
      t.string :hostname,     :null => false
      t.string :path
      t.string :locale,       :null => false, :default => 'en'
      t.boolean :is_mirrored, :null => false, :default => false
    end
    add_index :cms_sites, :hostname
    add_index :cms_sites, :is_mirrored

    # -- Layouts ------------------------------------------------------------
    create_table :cms_layouts do |t|
      t.integer :site_id,     :null => false
      t.integer :parent_id
      t.string  :app_layout
      t.string  :label,       :null => false
      t.string  :identifier,  :null => false
      t.text    :content,     text_limit
      t.text    :css,         text_limit
      t.text    :js,          text_limit
      t.integer :position,    :null => false, :default => 0
      t.boolean :is_shared,   :null => false, :default => false
      t.timestamps
    end
    add_index :cms_layouts, [:parent_id, :position]
    add_index :cms_layouts, [:site_id, :identifier], :unique => true

    # -- Pages --------------------------------------------------------------
    create_table :cms_pages do |t|
      t.integer :site_id,         :null => false
      t.integer :layout_id
      t.integer :parent_id
      t.integer :target_page_id
      t.string  :label,           :null => false
      t.string  :slug
      t.string  :full_path,       :null => false
      t.text    :content,         text_limit
      t.integer :position,        :null => false, :default => 0
      t.integer :children_count,  :null => false, :default => 0
      t.boolean :is_published,    :null => false, :default => true
      t.boolean :is_shared,       :null => false, :default => false
      t.timestamps
    end
    add_index :cms_pages, [:site_id, :full_path]
    add_index :cms_pages, [:parent_id, :position]

    # -- Page Blocks --------------------------------------------------------
    create_table :cms_blocks do |t|
      t.integer   :page_id,     :null => false
      t.string    :identifier,  :null => false
      t.text      :content
      t.timestamps
    end
    add_index :cms_blocks, [:page_id, :identifier]

    # -- Snippets -----------------------------------------------------------
    create_table :cms_snippets do |t|
      t.integer :site_id,     :null => false
      t.string  :label,       :null => false
      t.string  :identifier,  :null => false
      t.text    :content,     text_limit
      t.integer :position,    :null => false, :default => 0
      t.boolean :is_shared,   :null => false, :default => false
      t.timestamps
    end
    add_index :cms_snippets, [:site_id, :identifier], :unique => true
    add_index :cms_snippets, [:site_id, :position]

    # -- Files --------------------------------------------------------------
    create_table :cms_files do |t|
      t.integer :site_id,           :null => false
      t.integer :block_id
      t.string  :label,             :null => false
      t.string  :file_file_name,    :null => false
      t.string  :file_content_type, :null => false
      t.integer :file_file_size,    :null => false
      t.string  :description,       :limit => 2048
      t.integer :position,          :null => false, :default => 0
      t.timestamps
    end
    add_index :cms_files, [:site_id, :label]
    add_index :cms_files, [:site_id, :file_file_name]
    add_index :cms_files, [:site_id, :position]
    add_index :cms_files, [:site_id, :block_id]

    # -- Revisions -----------------------------------------------------------
    create_table :cms_revisions, :force => true do |t|
      t.string    :record_type, :null => false
      t.integer   :record_id,   :null => false
      t.text      :data,        text_limit
      t.datetime  :created_at
    end
    add_index :cms_revisions, [:record_type, :record_id, :created_at]

    # -- Categories ---------------------------------------------------------
    create_table :cms_categories, :force => true do |t|
      t.integer :site_id,          :null => false
      t.string  :label,            :null => false
      t.string  :categorized_type, :null => false
    end
    add_index :cms_categories, [:site_id, :categorized_type, :label], :unique => true

    create_table :cms_categorizations, :force => true do |t|
      t.integer :category_id,       :null => false
      t.string  :categorized_type,  :null => false
      t.integer :categorized_id,    :null => false
    end
    add_index :cms_categorizations, [:category_id, :categorized_type, :categorized_id], :unique => true,
      :name => 'index_cms_categorizations_on_cat_id_and_catd_type_and_catd_id'


    # -- Foreign keys, from 20140402033428_add_foreign_keys.rb
    add_foreign_key "cms_blocks", "cms_pages", name: "cms_blocks_page_id_fk", column: "page_id"
    add_foreign_key "cms_categories", "cms_sites", name: "cms_categories_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "cms_categorizations", "cms_categories", name: "cms_categorizations_category_id_fk", column: "category_id"
    add_foreign_key "cms_files", "cms_blocks", name: "cms_files_block_id_fk", column: "block_id"
    add_foreign_key "cms_files", "cms_sites", name: "cms_files_site_id_fk", column: "site_id"
    add_foreign_key "cms_layouts", "cms_layouts", name: "cms_layouts_parent_id_fk", column: "parent_id"
    add_foreign_key "cms_layouts", "cms_sites", name: "cms_layouts_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "cms_pages", "cms_layouts", name: "cms_pages_layout_id_fk", column: "layout_id"
    add_foreign_key "cms_pages", "cms_pages", name: "cms_pages_parent_id_fk", column: "parent_id"
    add_foreign_key "cms_pages", "cms_sites", name: "cms_pages_site_id_fk", column: "site_id", dependent: :delete
    add_foreign_key "cms_pages", "cms_pages", name: "cms_pages_target_page_id_fk", column: "target_page_id"
    add_foreign_key "cms_snippets", "cms_sites", name: "cms_snippets_site_id_fk", column: "site_id", dependent: :delete

  end
end
