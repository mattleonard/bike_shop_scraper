# Bicycle Technologies International (BTI) Unoffcial API

Since BTI has no official API, I built a webscraper that can be used as one. This is a Ruby On Rails app. I was going to refactor it but I am no longer using BTI so I have no login. If you would like me to update it for you, feel free to shoot me an email at mattleoanrdco@gmail.com. This web app also pushes to Shopify via their API. Be careful with this. I got shutdown for pushing all products public.

Setup
----------
1. Follow instructions on how to setup Sekrets key with you BTI log in info:

2. Put the following in your sekrets/cipertext file
```yaml
    :cust_id:         YOUR BTI CUSTOMER ID
    :u_name:          YOUR BTI USERNAME
    :pass:            YOUR BTI PASSWORD
    :shopify_key:     YOUR SHOPIFY KEY
    :shopify_secret:  YOUR SHOPIFY SECRET KEY
    :heroku_api:      HEROKU API KEY
```

Rake Tasks
----------

####BTI

Scrape BTI Product Group
`bundle exec rake scrape:bti:product_groups`

Scrape BTI Products
`bundle exec rake scrape:bti:update_stock`

####Shopify

Push new products to shopify
`bundle exec rake shopify:product:create_new`

Update stock on shopify
`bundle exec rake shopify:product:update_stock`

Update meta data for google adwords shopify app
`bundle exec rake shopify:product:update_google_category`

Removed archived products from shopify
`bundle exec rake shopify:product:remove_archived`

Disclaimer
----------
THIS SOFTWARE IS PROVIDED BY THE MATT LEONARD AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE MATT LEONARD OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
