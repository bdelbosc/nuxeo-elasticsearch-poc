#!/bin/bash

# Configure ES
ESHOST=${ESHOST:-localhost}
ESPORT=${ESPORT:-9200}
ESINDEX=${ESINDEX:-nuxeo}
ESSHARDS=${ESSHARDS:-5}
ESREPLICAS=${ESREPLICAS:-1}


read -r -p "Going to RESET the elasticsearch index $ESHOST:$ESPORT/$ESINDEX, are you sure? [y/N] " response
case $response in
    [yY][eE][sS]|[yY]) 
        ;;
    *)
	echo "Canceled, bye"
        exit 0
        ;;
esac
echo "### Delete index..."
curl -s -XDELETE "$ESHOST:$ESPORT/$ESINDEX" curl | grep error
echo "### Creating index $ESINDEX ..."
curl -s -XPUT "$ESHOST:$ESPORT/$ESINDEX" -d '{
  "settings" : { 
    "index.number_of_shards": '"$ESSHARDS"', 
    "index.number_of_replicas": '"$ESREPLICAS"',
    "analysis": {
      "analyzer": {
        "default" : {
          "tokenizer" : "standard",
          "filter": ["asciifolding", "lowercase", "french_stem", "elision", "stop"]
        },
        "path_analyzer": {
          "type": "custom",
          "tokenizer": "path_tokenizer"
        }
     },
     "filter" : {
       "elision" : {
         "type" : "elision",
         "articles" : ["l", "m", "t", "qu", "n", "s", "j"]
        }
      },
      "tokenizer": {
        "path_tokenizer": {
          "type": "path_hierarchy",
          "delimiter": "/"
        }
      }
    }
  }
}' |  grep error && exit -1

echo "### Creating mapping doc ..."
curl -s -X PUT "$ESHOST:$ESPORT/$ESINDEX/doc/_mapping" -d '{
        "doc" : {
            "_source" : {
                "excludes" : ["fulltext"]
            },
            "_size" : {
              "enabled" : true
            },
            "_timestamp" : { 
              "enabled" : true,
              "path" : "modified",
              "format": "yyyyMMdd HH:mm:ss"
            },
            "properties" : {
                "creator" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "fulltext" : {
                    "type" : "string",
                    "doc_values": false,
                    "store": true
                },
                "primarytype" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "mixintypes" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "contributors" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "tag" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "id" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "acl" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "name" : {
                    "type" : "string"
                },
                "path" : {
                    "type" : "multi_field",
                    "fields" : {
                        "path" : {
                           "type" : "string",
                           "index" : "not_analyzed"
                         },
                         "children" : {
                            "type" : "string",
                            "index_analyzer": "path_analyzer",
                            "search_analyzer": "keyword"
                         }
                      }
                },
                "title" : {
                    "type" : "string",
                    "boost": 2.0
                },
                "description" : {
                    "type" : "string",
                    "boost": 1.5
                },
                "modified" : {
                    "type" : "date",
                    "format": "yyyyMMdd HH:mm:ss"
                },
                "created" : {
                    "type" : "date",
                    "format": "yyyyMMdd HH:mm:ss"
                },
                "isversion" : {
                    "type" : "boolean",
                    "null_value" : false
                },
                "lifecyclestate" : {
                    "type" : "string",
                    "index": "not_analyzed"
                },
                "parentid" : {
                    "type" : "string",
                    "index": "not_analyzed"
                }
            }
        }
  }' | grep "error" && exit -2

echo "### Creating mapping audit ..."
curl -s -X PUT "$ESHOST:$ESPORT/$ESINDEX/audit/_mapping" -d '{
  "audit" : {
        "_timestamp" : { 
              "enabled" : true,
              "path" : "date",
              "format": "yyyyMMdd HH:mm:ss"
        },
        "properties" : {
          "category" : {
            "type" : "string",
            "index": "not_analyzed"
          },
          "comment" : {
            "type" : "string"
          },
          "date" : {
            "type" : "date",
            "format": "yyyyMMdd HH:mm:ss"
          },
          "docid" : {
            "type" : "string",
            "index": "not_analyzed"
          },
          "eventid" : {
            "type" : "string",
            "index": "not_analyzed"
          },
          "id" : {
            "type" : "long"
          },
          "lifecyclestate" : {
            "type" : "string",
            "index": "not_analyzed"
          },
          "logdate" : {
            "type" : "date",
            "format": "yyyyMMdd HH:mm:ss"
          },
          "path" : {
            "type" : "string",
            "index": "not_analyzed"
          },
          "primarytype" : {
            "type" : "string",
            "index": "not_analyzed"
          },
          "principal" : {
            "type" : "string",
            "index": "not_analyzed"
          }
        }
      }
  }' | grep "error" && exit -2

echo "### Done"
