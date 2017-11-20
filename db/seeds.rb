Blog.all.destroy_all
Post.all.destroy_all

Blog.create(name: "My Example Blog", subdomain: "example")
Blog.create(name: "Awesome Blog", subdomain: "awesome")

Post.create(title:"Gönderi bir", body:"Deneme iletisi", blog_id: 0)
Post.create(title:"Gönderi iki", body:"Deneme iletisi iki", blog_id: 1)
