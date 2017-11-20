# multitenant + subdomain

## Faydalanılan Kaynaklar/Çalışmalar

* [Basic Subdomains in Ruby on Rails](https://richonrails.com/articles/basic-subdomains-in-ruby-on-rails)
* [Apartment](https://github.com/influitive/apartment)

## Subdomain

Aşağıda yazılı komutlar ile modellerimizi oluşturuyoruz.

```bash
$ rails g model Blog name subdomain
$ rails g model Post title body:text blog:references
$ rake db:migrate
```

Modellerimizi oluşturuduktan sonra kontrol yapılarını oluşturuyoruz. 

```bash
$ rails g controller blogs index show
$ rails g controller posts show
```

Buraya kadar başarılı bir şekilde geldikten sonra yönlendirmeleri yapacağız. `config/routes.rb`dosyasını 
altta verilen kodlama gibi yapıyoruz. Bu kodlamada asıl olay 5 ve 6'ncı satırlarda gerçekleşmektedir. 
5'inci satır Rails'e 'www' alan adını `blog controller`da bulunan index yöntemiyle eşleştirilmesini sağlar.
`www.alanadi.com` adresini yazınca alt alan adı aramaması gerektiğini söyler. 6'ncı satır ise Rails'e alt alan
adı isteğini `blog/show` metoduna yönlendirmesini yapmaktadır.  

```ruby
Rails::Application.routes.draw do
  resources :posts
  resources :blogs

  match '/', to: 'blogs#index', constraints: { subdomain: 'www' }, via: [:get, :post, :put, :patch, :delete]
  match '/', to: 'blogs#show', constraints: { subdomain: /.+/ }, via: [:get, :post, :put, :patch, :delete]

  root to: "blogs#index"
end
```

Sonra uygulama denetleyicimizi(`app/controllers/application_controller.rb`) aşağıdaki gibi düzenleyeceğiz. Burada belirli bir blog'u  
subdomain'e göre bulacak ve sonucu döndürecek `get_blog` yöntemi oluşturduk.

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :get_blog

private
  def get_blog

    blogs = Blog.where(subdomain: request.subdomain)

    if blogs.count > 0
      @blog = blogs.first
    elsif request.subdomain != 'www'
      redirect_to root_url(subdomain: 'www')
    end
  end
end
```

Buradan sonra Blog ve Post modellerimizin kontrol ve görünüm yapılarını aşağıda verilen kodlarda ki gibi oluşturuyoruz.

`app/controller/blogs_controller.rb`

```ruby
class BlogsController < ApplicationController
  def index
    @blogs = Blog.all
  end

  def show
    @posts = @blog.post
  end
end
```

`app/controller/posts_controller.rb`

```ruby
class PostsController < ApplicationController
  def show
    @post = @blog.post.find(params[:id])
  end
end
```

`app/views/layouts/application.html.erb`

```html
<!DOCTYPE html>
<html>
<head>
  <title>SubdomainsExample</title>
  <%= stylesheet_link_tag    "application", media: "all", "data-turbolinks-track" => true %>
  <%= javascript_include_tag "application", "data-turbolinks-track" => true %>
  <%= stylesheet_link_tag "http://yandex.st/bootstrap/3.0.2/css/bootstrap.min.css", media: "all" %>
  <%= javascript_include_tag "http://yandex.st/bootstrap/3.0.2/js/bootstrap.min.js" %>
  <%= csrf_meta_tags %>
</head>
<body>
<div class="container">
<%= yield %>
</div>
</body>
</html>
```

`app/views/blogs/index.html.erb`

```html
<h1>Blogs on this Server</h1>

<ul>
  <% @blogs.each do |blog| %>
    <li><%= link_to blog.name, root_url(subdomain: blog.subdomain) %></li>
  <% end %>
</ul>
```

`app/views/blogs/show.html.erb`

```html
<h1><%= @blog.name %></h1>
<hr />
<% @posts.each do |post| %>

<h3><%= post.title %></h3>
<p><%= truncate post.body, length: 160 %></p>
<%= link_to "Read More", post %>
<% end %>
```

`app/views/posts/show.html.erb`

```html
<h1><%= @post.title %></h1>
<p>
  <%= @post.body %>
</p>
```

Son olarak `db/seed.rb` dosyamızı aşağıdaki gibi oluşturuyoruz ve `$ rake db:seed`komutunu çalıştırıyoruz.

```ruby
Blog.create(id: 0, name: "My Example Blog", subdomain: "example")
Blog.create(id: 1, name: "Awesome Blog", subdomain: "awesome")

Post.create(title:"Gönderi bir", body:"Deneme iletisi", blog_id: 0)
Post.create(title:"Gönderi iki", body:"Deneme iletisi iki", blog_id: 1)
```

Şimdi uygulamamızı test etme zamanı. Development ortamında test yapmanın en kolay yolu `vcap.me` alan adını kullanmaktır. 
`vcamp.me` ve buna bağlı tüm alt alanlar localhost'a işaret eder. Rails sunucusu çalıştırın ve [http://www.vcap.me:3000](http://www.vcap.me:3000)! adresine gidin. 
Bir blog listesi göreceksiniz. Bu bloglardan birine tıklamak, belirli blog'u kendi yazılarıyla birlikte gösterecektir. 
Daha sonra, yazıyı görüntülemek için iletiye tıklayabilirsiniz.

## Multitenant - Apartment Gem

Gemfile dosyanıza aşağıdaki satırı ekleyin ve `$ bundle install` komutunu çalıştırın.

```ruby
gem 'apartment'
```

Sonra `apartment` kütüphanelerini sistemimize aşağıdaki komutu çalıştırarak yüklüyoruz.

```bash
$ bundle exec rails generate apartment:install
``` 

Bu komut ile birlikte `config/initializers/apartment.rb` ilklendirme dosyası oluşacaktır.
Bu dosyada bulunan

```ruby
# config.excluded_models = %w{ Tenant }  satırını

config.excluded_models = %w{ Blog } 
```

olarak düzenliyoruz.

```ruby

# config.tenant_names = lambda { ToDo_Tenant_Or_User_Model.pluck :database } satırınıda

config.tenant_names = lambda { Blog.pluck :subdomain }
```

olarak düzenliyoruz.

**Önemli nokta** apartment geminin Rails 5.0 'da çalışabilmesi için bu dosyanın alt taraflarında bulunan 

```ruby
Rails.application.config.middleware.use "Apartment::Elevators::Subdomain"
```

satırında bulunan **çift tırnak/kesme işaretlerini** kaldırıyoruz. Bu işaretleri kaldırmaz isek uygulama hata verecektir.
Son olarak `config/application.rb`dosyamızı aşağıdaki gibi düzenliyoruz.

```ruby
require_relative 'boot'

require 'rails/all'

require 'apartment/elevators/subdomain'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MultitenantApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1
    Rails.application.config.middleware.use Apartment::Elevators::Subdomain
    Apartment::Elevators::Subdomain.excluded_subdomains = ['www']
    
  end
end
```

Bu düzenlemeyi yapıp sunucumuzu çalıştırdıktan sonra multi tenant yapısının çalıştığını göreceksiniz. Son olarak
multitenant yapısının yeni bir model üzerinde çalıştığını görmek için aşağıdaki komutları çalıştırın.

```bash
$ rails generate scaffold Project title

$ rake db:migrate
```

Bu iki komutu çalıştırdıktan sonra aşağıki gibi bir çıktı alacaksınız.

![](img.png)

Burada multi tenant yapımızız her oluşturulan blog'a eklenen projeler için oluştuğunu göreceksiniz.
