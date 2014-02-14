# POC elasticsearch/kibana

This is a POC to import nuxeo content into elasticsearch.

## Requirements
- Nuxeo on PostgreSQL >= 9.2 to have the json support
- GNU parallel

      sudo apt-get install parallel
  
- ElasticSearch >= 1.0.0

     wget --no-check-certificate https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.0.deb
     sudo dpkg -i elasticsearch-1.0.0.deb

- Kibana >= 3.0.0milestone5

    wget --no-check-certificate https://download.elasticsearch.org/kibana/kibana/kibana-3.0.0milestone5.zip
    unzip on you /var/www and use your apache/nginx or access point your browser to the index.html

## Dump the Nuxeo content
The documents:

    PGPASSWORD=secret DBNAME=nuxeo DBUSER=nuxeo DBHOST=localhost ./dump-doc.sh

The audit table:

    PGPASSWORD=secret DBNAME=nuxeo DBUSER=nuxeo DBHOST=localhost ./dump-audit.sh

## Initialize the elasticsearch index

ESHOST=localhost ESPORT=9200 ./init-index.sh

## Import the documents and audit

Import the documents dump into elasticsearch:
ESHOST=localhost ESPORT=9200 ./import.sh /tmp/dump-nuxeo-doc.tgz

Import the audit dump into elasticsearch:
ESHOST=localhost ESPORT=9200 ./import.sh /tmp/dump-nuxeo-doc.tgz


## Import the kibana dashboards

