# Web Scraper For Bike Distributor
## Pushes products to shopify

I was having difficulty maintaining the stock between my bike shop and the distributors inventory.
So I built a webscraper that scraped all 23,000 products and pushed them to Shopify via their API. It would also update the stock and new product every night. I was going to refactor it but I am no longer using my distributor. If you would like me to update it for you, feel free to shoot me an email at mattleonardco@gmail.com. Be careful with this.

More in depth article on why I built this: [here](http://blog.mattl.co/how-i-automated-my-bike-shop)

Setup
----------
1. Follow instructions on how to setup Sekrets key with you distributor log in info:

2. Put the following in your sekrets/cipertext file
```yaml
    :cust_id:         YOUR CUSTOMER ID
    :u_name:          YOUR USERNAME
    :pass:            YOUR PASSWORD
    :shopify_key:     YOUR SHOPIFY KEY
    :shopify_secret:  YOUR SHOPIFY SECRET KEY
    :heroku_api:      HEROKU API KEY
```

Rake Tasks
----------

####Distributor

Scrape Product Group
`bundle exec rake scrape:distributor:product_groups`

Scrape Products
`bundle exec rake scrape:distributor:update_stock`

####Shopify

Push new products to shopify
`bundle exec rake shopify:product:create_new`

Update stock on shopify
`bundle exec rake shopify:product:update_stock`

Update meta data for google adwords shopify app
`bundle exec rake shopify:product:update_google_category`

Removed archived products from shopify
`bundle exec rake shopify:product:remove_archived`
