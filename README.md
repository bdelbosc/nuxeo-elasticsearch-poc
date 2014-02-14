# POC elasticsearch/kibana

This is a POC to import large Nuxeo content into elasticsearch.

To be as efficient as possible:
- the dump is done at SQL level, PostgreSQL is able to output the elastic bulk format directly
- the dump is splitted and imported concurrently with the bulk API.

Note that this is only a POC and only few Nuxeo fields are exported.

There are two elasticsearch type one for the documents and one for the audit log.

## Requirements

- A Nuxeo database instance on PostgreSQL >= 9.2 (required to have the json support)

- GNU parallel

      sudo apt-get install parallel
  
- ElasticSearch >= 1.0.0

     wget --no-check-certificate https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.0.deb
     sudo dpkg -i elasticsearch-1.0.0.deb

- Kibana >= 3.0.0milestone5

    wget --no-check-certificate https://download.elasticsearch.org/kibana/kibana/kibana-3.0.0milestone5.zip
    # Then unzip on you /var/www or point your browser to the index.html.

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

From the kibana navigation load **nuxeo-dashboard.json** and **audit-dashboard.json**.

## About Nuxeo

Nuxeo provides a modular, extensible Java-based [open source software platform for enterprise content management] [1] and packaged applications for [document management] [2], [digital asset management] [3] and [case management] [4]. Designed by developers for developers, the Nuxeo platform offers a modern architecture, a powerful plug-in model and extensive packaging capabilities for building content applications.

[1]: http://www.nuxeo.com/en/products/ep
[2]: http://www.nuxeo.com/en/products/document-management
[3]: http://www.nuxeo.com/en/products/dam
[4]: http://www.nuxeo.com/en/products/case-management

More information on: <http://www.nuxeo.com/>

