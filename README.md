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

      wget --no-check-certificate https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.0.0.deb && sudo dpkg -i elasticsearch-1.0.0.deb


- Kibana >= 3.0.0milestone5

       wget --no-check-certificate https://download.elasticsearch.org/kibana/kibana/kibana-3.0.0milestone5.zip
       Then unzip on you /var/www or point your browser to the index.html.


## Dump the Nuxeo content

The documents:

    PGPASSWORD=secret DBNAME=nuxeo DBUSER=nuxeo DBHOST=localhost ./dump-doc.sh

Here is the output

    ### Dump database ... Fri Feb 14 17:38:18 CET 2014
    creating file `doc000000'
    creating file `doc000001'
    ...
    creating file ‘doc000087’
    real	3m29.814s
    user	0m3.698s
    sys	0m1.010s
    ### Total number of docs
    87039
    ### Creating archive...
    real	0m6.734s
    user	0m6.410s
    sys	0m0.310s
    ### Done:  Mon Feb 17 10:19:44 CET 2014
    -rw-rw-r-- 1 nuxeo nuxeo 49M Feb 17 10:19 dump-nuxeo-doc.tgz
    /tmp/dump-nuxeo-doc.tgz

The audit table:

    PGPASSWORD=secret DBNAME=nuxeo DBUSER=nuxeo DBHOST=localhost ./dump-audit.sh

Output:

    ### Dump database ... Fri Feb 14 17:43:28 CET 2014
    creating file `audit000000'
    ...
    creating file ‘audit007354’
    real	11m25.778s
    user	0m39.172s
    sys	0m12.644s
    ### Total number of docs
    7354393
    ### Creating archive...
    real	0m28.706s
    user	0m26.112s
    sys	0m2.508s
    ### Done:  Mon Feb 17 10:34:51 CET 2014
    -rw-rw-r-- 1 nuxeo nuxeo 106M Feb 17 10:34 dump-nuxeo-audit.tgz


## Initialize the elasticsearch index

    ESHOST=localhost ESPORT=9200 ./init-index.sh

Output

    Going to RESET the elasticsearch index localhost:9200/nuxeo, are you sure? [y/N] y
    ### Delete index...
    ### Creating index nuxeo ...
    ### Creating mapping doc ...
    ### Creating mapping audit ...
    ### Done


## Import content into elasticsearch

Import the documents dump into elasticsearch:

    ESHOST=localhost ESPORT=9200 ./import.sh /tmp/dump-nuxeo-doc.tgz

Output


    ### Number of doc before import
    {"count":0,"_shards":{"total":5,"successful":5,"failed":0}}
    ### Total doc to import: 
    87039
    ### Import ...
    real    1m19.391s
    user    0m1.684s
    sys     0m2.480s
    ### Number of doc after import
    + curl -XGET localhost:9200/nuxeo/doc/_count
    {"count":85950,"_shards":{"total":5,"successful":5,"failed":0}}+ set +x
 
 
Import the audit dump into elasticsearch:

    ESHOST=localhost ESPORT=9200 ESTYPE=audit ./import.sh /tmp/dump-nuxeo-audit.tgz

Output

    ### Number of doc before import
    {"count":0,"_shards":{"total":5,"successful":5,"failed":0}}
    ### Total doc to import: 
    7354393
    ### Import ...
    real    20m9.453s
    user    1m5.992s
    sys     1m38.818s
    ### Number of doc after import
    + curl -XGET localhost:9200/nuxeo/audit/_count
    {"count":7354393,"_shards":{"total":5,"successful":5,"failed":0}}+ set +x


## Import the kibana dashboards

From the kibana navigation load **nuxeo-dashboard.json** and **audit-dashboard.json**.

## About Nuxeo

Nuxeo provides a modular, extensible Java-based [open source software platform for enterprise content management] [1] and packaged applications for [document management] [2], [digital asset management] [3] and [case management] [4]. Designed by developers for developers, the Nuxeo platform offers a modern architecture, a powerful plug-in model and extensive packaging capabilities for building content applications.

[1]: http://www.nuxeo.com/en/products/ep
[2]: http://www.nuxeo.com/en/products/document-management
[3]: http://www.nuxeo.com/en/products/dam
[4]: http://www.nuxeo.com/en/products/case-management

More information on: <http://www.nuxeo.com/>

