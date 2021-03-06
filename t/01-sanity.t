# vi:filetype=

use t::OpenResty;

plan tests => 3 * blocks() - 3 * 2;
#plan tests => 3 * blocks();

run_tests;

__DATA__

=== TEST 1: Login w/o password
--- request
GET /=/login/$TestAccount.Admin
--- response
{"success":0,"error":"$TestAccount.Admin is not anonymous."}



=== TEST 2: Delete existing models (w/o login)
--- request
DELETE /=/model.js
--- response
{"success":0,"error":"Login required."}



=== TEST 3: Login with password but w/o cookie
--- request
GET /=/login/$TestAccount.Admin/$TestPass
--- response_like
^{"success":1,"session":"[-\w]+","account":"$TestAccount","role":"Admin"}$



=== TEST 4: Delete existing models (wrong way)
--- request
DELETE /=/model.js
--- response
{"success":0,"error":"Login required."}



=== TEST 5: Login with password and cookie
--- request
GET /=/login/$TestAccount.Admin/$TestPass?_use_cookie=1
--- response_like
^{"success":1,"session":"[-\w]+","account":"$TestAccount","role":"Admin"}$



=== TEST 6: Delete existing models
--- request
DELETE /=/model.js
--- response
{"success":1}



=== TEST 7: Get model list
--- request
GET /=/model.js
--- response
[]



=== TEST 8: Create a model
--- request
POST /=/model/Bookmark.js
{
    "description": "我的书签",
    "columns": [
        { "name": "id", "type": "serial", "label": "ID" },
        { "name": "title", "type":"text", "label": "标题" },
        { "name": "url", "type":"varchar(20)", "label": "网址" }
    ]
}
--- response
{"success":1,"warning":"Column \"id\" reserved. Ignored."}



=== TEST 9: check the model list again
--- request
GET /=/model.js
--- response
[{"src":"/=/model/Bookmark","name":"Bookmark","description":"我的书签"}]



=== TEST 10: check the column
--- request
GET /=/model/Bookmark.js
--- response
{
  "columns":
   [
    {"name":"id","label":"ID","type":"serial"},
    {"name":"title","default":null,"label":"标题","type":"text","unique":false,"not_null":false},
    {"name":"url","default":null,"label":"网址","type":"character varying(20)","unique":false,"not_null":false}
   ],
  "name":"Bookmark",
  "description":"我的书签"
}



=== TEST 11: access inexistent models
--- request
GET /=/model/Foo.js
--- response
{"success":0,"error":"Model \"Foo\" not found."}



=== TEST 12: insert a single record
--- request
POST /=/model/Bookmark/~/~
{ "title": "Yahoo Search", "url": "http://www.yahoo.cn" }
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/Bookmark/id/1"}



=== TEST 13: insert another record
--- request
POST /=/model/Bookmark/~/~.js
{ "title": "Yahoo Search", "url": "http://www.yahoo.cn" }
--- response
{"success":1,"rows_affected":1,"last_row":"/=/model/Bookmark/id/2"}



=== TEST 14: insert multiple records at a time
--- request
POST /=/model/Bookmark/~/~.js
[
    { "title": "Google搜索", "url": "http://www.google.cn" },
    { "url": "http://www.baidu.com" },
    { "title": "Perl.com", "url": "http://www.perl.com" }
]
--- response
{"success":1,"rows_affected":3,"last_row":"/=/model/Bookmark/id/5"}



=== TEST 15: read a record
--- request
GET /=/model/Bookmark/id/1.js
--- response
[{"url":"http://www.yahoo.cn","title":"Yahoo Search","id":"1"}]



=== TEST 16: read another record
--- request
GET /=/model/Bookmark/id/5.js
--- response
[{"url":"http://www.perl.com","title":"Perl.com","id":"5"}]



=== TEST 17: read urls of all the records
--- request
GET /=/model/Bookmark/url/~.js
--- response
[
    {"url":"http://www.yahoo.cn"},
    {"url":"http://www.yahoo.cn"},
    {"url":"http://www.google.cn"},
    {"url":"http://www.baidu.com"},
    {"url":"http://www.perl.com"}
]



=== TEST 18: select records
--- request
GET /=/model/Bookmark/url/http://www.yahoo.cn.js
--- response
[
    {"url":"http://www.yahoo.cn","title":"Yahoo Search","id":"1"},
    {"url":"http://www.yahoo.cn","title":"Yahoo Search","id":"2"}
]



=== TEST 19: read all records
--- request
GET /=/model/Bookmark/~/~.js
--- response
[
    {"url":"http://www.yahoo.cn","title":"Yahoo Search","id":"1"},
    {"url":"http://www.yahoo.cn","title":"Yahoo Search","id":"2"},
    {"url":"http://www.google.cn","title":"Google搜索","id":"3"},
    {"url":"http://www.baidu.com","title":null,"id":"4"},
    {"url":"http://www.perl.com","title":"Perl.com","id":"5"}
]



=== TEST 20: delete a record
--- request
DELETE /=/model/Bookmark/id/2.js
--- response
{"success":1,"rows_affected":1}



=== TEST 21: check the record just deleted
--- request
GET /=/model/Bookmark/id/2.js
--- response
[]



=== TEST 22: update a nonexistent record
--- request
PUT /=/model/Bookmark/id/2.js
{ "title": "Blah blah blah" }
--- response
{"success":0,"rows_affected":0}



=== TEST 23: update an existent record
--- request
PUT /=/model/Bookmark/id/3.js
{ "title": "Blah blah blah" }
--- response
{"success":1,"rows_affected":1}



=== TEST 24: check if the record is indeed changed
--- request
GET /=/model/Bookmark/id/3.js
--- response
[{"url":"http://www.google.cn","title":"Blah blah blah","id":"3"}]



=== TEST 25: update an existent record using POST
--- request
POST /=/put/model/Bookmark/id/3.js?_last_response=1234
{ "title": "Howdy!" }
--- response
{"success":1,"rows_affected":1}



=== TEST 26: Check the last response
--- request
GET /=/last/response/1234
--- response
{"success":1,"rows_affected":1}



=== TEST 27: Check the last response with a wrong ID
--- request
GET /=/last/response/567
--- response
{"success":0,"error":"No last response found for ID 567"}



=== TEST 28: Check the last response with no ID
--- request
GET /=/last/response
--- response
{"success":0,"error":"No last response ID specified."}



=== TEST 29: Check the last response (with _callback)
--- request
GET /=/last/response/1234?_callback=foo
--- response
foo({"success":1,"rows_affected":1});



=== TEST 30: Check the last response again
--- request
GET /=/last/response/1234
--- response
{"success":1,"rows_affected":1}



=== TEST 31: check if the record is indeed changed
--- request
GET /=/model/Bookmark/id/3.js?_last_response=1234
--- response
[{"url":"http://www.google.cn","title":"Howdy!","id":"3"}]



=== TEST 32: Check the last response again (GET has effect too)
--- request
GET /=/last/response/1234
--- response
[{"url":"http://www.google.cn","title":"Howdy!","id":"3"}]



=== TEST 33: Change the name of the model
--- request
PUT /=/model/Bookmark.js?_last_response=hello,world
{ "name": "MyFavorites", "description": "我的最爱" }
--- response
{"success":"1"}



=== TEST 34: Check the last response again (PUT has effect)
--- request
GET /=/last/response/hello,world
--- response
{"success":"1"}



=== TEST 35: Check the new model
--- request
GET /=/model/MyFavorites.js
--- response
{
  "columns":
   [
    {"name":"id","label":"ID","type":"serial"},
    {"name":"title","default":null,"label":"标题","type":"text","unique":false,"not_null":false},
    {"name":"url","default":null,"label":"网址","type":"character varying(20)","unique":false,"not_null":false}
   ],
  "name":"MyFavorites",
  "description":"我的最爱"
}



=== TEST 36: Change the name and type of title
--- request
PUT /=/model/MyFavorites/title
{ "name": "count", "type": "text" }
--- response
{"success":1}



=== TEST 37: Get model list
--- request
GET /=/model.js
--- response
[{"src":"/=/model/MyFavorites","name":"MyFavorites","description":"我的最爱"}]



=== TEST 38: Check the new column
--- request
GET /=/model/MyFavorites/count
--- response
{"name":"count","default":null,"label":"标题","type":"text","unique":false,"not_null":false}



=== TEST 39: Create a new column of the boolean type
--- request
POST /=/model/MyFavorites/~
{ "name": "disabled", "type": "boolean", "label": "Disabled" }
--- response
{"success":1,"src":"/=/model/MyFavorites/disabled"}



=== TEST 40: Change the name and type of title to incompactible types
--- debug: 1
--- request
PUT /=/model/MyFavorites/count
{ "name": "count", "type": "real" }
--- response
{"error":"column \"count\" of relation \"MyFavorites\" already exists","success":0}



=== TEST 41: Change the name and type of title to incompactible types
--- debug: 0
--- request
PUT /=/model/MyFavorites/count
{ "name": "count", "type": "real" }
--- response
{"success":0,"error":"Operation failed."}



=== TEST 42: Change the name and type of title to incompactible types
--- debug: 1
--- request
PUT /=/model/MyFavorites/count
{ "type": "real" }
--- response
{"error":"column \"count\" cannot be cast to type \"pg_catalog.float4\"","success":0}



=== TEST 43: Change the name and type of title to incompactible types
--- debug: 0
--- request
PUT /=/model/MyFavorites/count
{ "type": "real" }
--- response
{"success":0,"error":"Operation failed."}



=== TEST 44: logout
--- request
GET /=/logout
--- response
{"success":1}

