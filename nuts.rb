require 'camping'
Camping.goes :Nuts

require 'active_record'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'sqlite3://localhost/.camping.db')

module Nuts::Models
  class Page < Base
  end

  class BasicFields < V 1.0
    def self.up
      create_table Page.table_name do |t|
        t.string :title
        t.text   :content
        # This gives us created_at and updated_at
        t.timestamps
      end
    end

    def self.down
      drop_table Page.table_name
    end
  end

  class AddTagColumn < V 1.1
    def self.change
      add_column Page.table_name, :tag, :string
      Page.reset_column_information
    end
  end

end

module Nuts::Controllers
  class Pages
    def get
      # Only fetch the titles of the pages.
      @pages = Page.all(:select => "title")
      render :list
    end
  end

  class PageX
    def get(title)
      if @page = Page.find_by_title(title)
        render :view
      else
        redirect PageXEdit, title
      end
    end

    def post(title)
      # If it doesn't exist, initialize it:
      @page = Page.find_or_initialize_by_title(title)
      @page.content = @input.content
      @page.save
      redirect PageX, title
    end
  end

  class PageNew
    def get
      render :new
    end
    def post
      @page = Page.new
      @page.title   = @input.title
      @page.content = @input.content
      @page.save
      redirect PageX, @input.title
    end
  end

  class PageXEdit
    def get(title)
      @page = Page.find_or_initialize_by_title(title)
      render :edit
    end
  end

  class PageXDelete
    def get(title)
      @page = Page.find_or_initialize_by_title(title)
      @page.destroy

      redirect Pages
    end
  end

end

module Nuts::Views
  def layout
    xhtml_strict do
      head {title "Camping"}
      body {self << yield}
    end
  end
  def list
    h1 "All pages"
    ul do
      @pages.each do |page|
        li do
          a page.title, :href => R(PageX, page.title)
        end
      end
    end
    a "new", :href => R(PageNew)
  end

  def view
    h1 @page.title
    self << @page.content
    br
    a "top", :href => R(Pages)
    b " | "
    a "edit", :href => R(PageXEdit, @page.title)
    b " | "
    a "delete", :href => R(PageXDelete, @page.title)
  end

  def new
    form :action => R(PageNew), :method => :post do
      text "title:"
      textarea "", :name => :title, :rows => 1, :cols => 40
      br
      textarea "", :name => :content,
        :rows => 10, :cols => 50
      br
      input :type => :submit, :value => "Submit!"
    end
  end

  def edit
    h1 @page.title
    form :action => R(PageX, @page.title), :method => :post do
      textarea @page.content, :name => :content,
        :rows => 10, :cols => 50
      br
      input :type => :submit, :value => "Submit!"
    end
  end
end

  def Nuts.create
    Nuts::Models.create_schema
  end