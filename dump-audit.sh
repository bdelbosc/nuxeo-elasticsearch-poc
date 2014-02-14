#!/bin/bash 

# Configure database input
DBNAME=${DBNAME:-nuxeo}
DBUSER=${DBUSER:-nuxeo}
DBHOST=${DBHOST:-localhost}
DBPORT=${DBPORT:-5432}
# Configure ES index and type
ESINDEX=${ESINDEX:-nuxeo}
ESTYPE=${ESTYPE:-audit}

TMPDIR=/tmp/dump-$ESINDEX-$ESTYPE

mkdir -p $TMPDIR || exit -1
cd $TMPDIR || exit -2
echo "### Dump database ..." `date`
time psql -h $DBHOST -p $DBPORT -U $DBUSER $DBNAME -t -A -F "
"  -c "SELECT '{\"index\":{\"_index\":\"$ESINDEX\",\"_type\":\"$ESTYPE\",\"_id\":' || r.id::text ||'}}' AS A,  row_to_json(r) AS S FROM (
SELECT log_id AS id, log_event_comment AS comment, log_event_category AS category, log_doc_type AS primarytype, log_event_id AS eventid,  to_char(log_event_date,'YYYYMMDD HH24:MI:SS') AS date,
   log_principal_name AS principal, log_doc_uuid AS docid, log_doc_path AS path, log_doc_life_cycle AS lifecyclestate, to_char(log_date,'YYYYMMDD HH24:MI:SS') AS logdate
   FROM nxp_logs
-- LIMIT 10
) AS r;" | split --verbose -l 2000 -d -a 6 - -- $ESTYPE || exit -4
echo "### Total number of docs"
echo $((`cat * | wc -l`/2))
cd .. || exit -3
DIR=`basename $TMPDIR`
echo "### Creating archive..."
time tar czf $DIR.tgz $DIR || exit -4
echo "### Done: " `date`
ls -lh $DIR.tgz
readlink -e $DIR.tgz
#echo "### Cleaning ..."
rm -rf $TMPDIR



