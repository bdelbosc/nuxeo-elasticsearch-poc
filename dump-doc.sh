#!/bin/bash 

# Configure database input
DBNAME=${DBNAME:-nuxeo}
DBUSER=${DBUSER:-nuxeo}
DBHOST=${DBHOST:-localhost}
DBPORT=${DBPORT:-5432}
# Configure ES index and type
ESINDEX=${ESINDEX:-nuxeo}
ESTYPE=${ESTYPE:-doc}

TMPDIR=/tmp/dump-$ESINDEX-$ESTYPE

mkdir -p $TMPDIR || exit -1
cd $TMPDIR || exit -2
echo "### Dump database ..." `date`
time psql -h $DBHOST -p $DBPORT -U $DBUSER $DBNAME -t -A -F "
"  -c "CREATE OR REPLACE FUNCTION nx_path(docid varchar(36))
RETURNS varchar
AS \$\$
-- Return path of a doc, only used for SQL debug purpose
BEGIN
  RETURN (SELECT array_to_string(array_agg(name),'/','/')
    FROM hierarchy h
    JOIN (SELECT unnest(ancestors) AS id FROM ancestors WHERE id=docid
          UNION ALL SELECT docid) v ON v.id = h.id);
END \$\$
LANGUAGE plpgsql
STABLE;
CREATE OR REPLACE FUNCTION nx_aclr_json(acl varchar)
RETURNS varchar[]
AS \$\$
-- Return a positiv ACLR
DECLARE
  ret varchar[];
  r record;
BEGIN
  FOR r IN SELECT ace FROM regexp_split_to_table(acl, ',') AS ace LOOP
    IF (r.ace = '-Everyone') THEN
       CONTINUE;
    END IF;
    ret := array_append(ret, r.ace::varchar);
  END LOOP;
  RETURN ret;
END \$\$
LANGUAGE plpgsql
STABLE;
SELECT '{\"index\":{\"_index\":\"$ESINDEX\",\"_type\":\"$ESTYPE\",\"_id\":\"' || r.id ||'\"}}' AS A,  row_to_json(r) AS S FROM (
SELECT h.id, h.parentid, h.name, h.primarytype, array_to_json(h.mixintypes) AS mixintypes, h.isversion, 
  d.title, d.description, d.creator, to_char(d.modified,'YYYYMMDD HH24:MI:SS') AS modified, to_char(d.created,'YYYYMMDD HH24:MI:SS') AS created,
  m.lifecyclestate,
  regexp_replace(f.fulltext::text, \$\$'|:|,|[0-9]\$\$, ' ', 'g') AS fulltext,
--  c.name,
--  c.length,
  nx_path(h.id) AS path,
  nx_aclr_json(aclr.acl) AS acl,
  (SELECT array_agg(name) FROM hierarchy WHERE id IN (SELECT target FROM relation WHERE source=h.id)) AS tag,
  (SELECT array_agg(item) FROM dc_contributors WHERE id=h.id) AS contributors
FROM hierarchy h 
JOIN dublincore d ON h.id=d.id
JOIN misc m ON h.id=m.id
JOIN hierarchy_read_acl a ON h.id=a.id
JOIN aclr ON a.acl_id=aclr.acl_id
LEFT JOIN fulltext f ON h.id=f.id
-- LEFT JOIN hierarchy hh on h.id=hh.parentid
-- LEFT JOIN content c on hh.id=c.id
WHERE not isproperty
--  h.primarytype in ('Root', 'Workspace', 'Folder', 'File') 
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
